import Foundation
import CoreData
import UIKit

@MainActor
final class PODViewModel: ObservableObject {
    @Published var recipientName: String
    @Published var capturedPhoto: UIImage?
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

        guard let signatureData = signature.pngData() else {
            errorMessage = "Failed to render signature. Please try again."
            isSubmitting = false
            return
        }

        // Compress photo to JPEG at 0.8 quality to keep binary size reasonable.
        let photoData = capturedPhoto?.jpegData(compressionQuality: 0.8)

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
                pod.signatureImage = signatureData
                pod.photoImage = photoData
                pod.capturedAt = now

                let fetch = NSFetchRequest<DeliveryEntity>(entityName: "DeliveryEntity")
                fetch.predicate = NSPredicate(format: "deliveryId == %@", deliveryId)
                fetch.fetchLimit = 1
                if let d = try context.fetch(fetch).first {
                    d.status = "completed"
                }

                try context.save()
            }

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
