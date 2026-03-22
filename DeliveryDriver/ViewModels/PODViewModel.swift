import Foundation
import CoreData
import UIKit

@MainActor
final class PODViewModel: ObservableObject {
    @Published var recipientName: String
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var submitted = false

    private let delivery: DeliveryEntity
    private let persistence = PersistenceController.shared

    init(delivery: DeliveryEntity) {
        self.delivery = delivery
        self.recipientName = delivery.recipientName ?? ""
    }

    func submit(signature: UIImage, onSuccess: @escaping () -> Void) async {
        isSubmitting = true
        errorMessage = nil

        guard let pngData = signature.pngData() else {
            errorMessage = "Failed to render signature. Please try again."
            isSubmitting = false
            return
        }

        let context = persistence.container.newBackgroundContext()
        let deliveryId = delivery.deliveryId ?? ""
        let name = recipientName
        let now = Date()

        do {
            try await context.perform {
                let pod = PODEntity(context: context)
                pod.podId = UUID().uuidString
                pod.deliveryId = deliveryId
                pod.recipientName = name
                pod.signatureImage = pngData
                pod.capturedAt = now

                // Mark delivery as completed.
                let fetch = NSFetchRequest<DeliveryEntity>(entityName: "DeliveryEntity")
                fetch.predicate = NSPredicate(format: "deliveryId == %@", deliveryId)
                fetch.fetchLimit = 1
                if let d = try context.fetch(fetch).first {
                    d.status = "completed"
                }

                try context.save()
            }

            // Merge and immediately attempt sync.
            await persistence.container.viewContext.perform {
                self.persistence.container.viewContext.refreshAllObjects()
            }
            SyncService.shared.syncNow()
            submitted = true
            onSuccess()
        } catch {
            errorMessage = "Failed to save POD: \(error.localizedDescription)"
        }

        isSubmitting = false
    }
}
