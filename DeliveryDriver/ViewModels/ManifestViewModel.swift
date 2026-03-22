import Foundation
import CoreData

@MainActor
final class ManifestViewModel: ObservableObject {
    @Published var isDownloading = false
    @Published var errorMessage: String?
    @Published var lastDownloadedAt: Date?

    private let api = APIClient.shared
    private let persistence = PersistenceController.shared
    private let settings: SettingsStore = .shared

    init() {
        loadLastDownloadedAt()
    }

    func downloadManifest() async {
        guard let url = settings.manifestURL else {
            errorMessage = "Manifest URL is not configured. Check Settings."
            return
        }
        isDownloading = true
        errorMessage = nil

        do {
            let data = try await api.fetchManifest(url: url)
            try await parseAndPersist(data: data)
            loadLastDownloadedAt()
        } catch {
            errorMessage = error.localizedDescription
        }

        isDownloading = false
    }

    // MARK: - Private

    private func parseAndPersist(data: Data) async throws {
        // Support both bare array and wrapped {"deliveries":[...]} response.
        let deliveries: [ManifestDelivery]
        if let array = try? JSONDecoder().decode([ManifestDelivery].self, from: data) {
            deliveries = array
        } else {
            let wrapped = try JSONDecoder().decode(ManifestResponse.self, from: data)
            deliveries = wrapped.deliveries ?? []
        }

        let context = persistence.container.newBackgroundContext()
        let now = Date()

        try await context.perform {
            // Replace existing manifest records with fresh download.
            let deleteManifest = NSFetchRequest<NSFetchRequestResult>(entityName: "ManifestEntity")
            let deleteDelivery = NSFetchRequest<NSFetchRequestResult>(entityName: "DeliveryEntity")
            try context.execute(NSBatchDeleteRequest(fetchRequest: deleteManifest))
            try context.execute(NSBatchDeleteRequest(fetchRequest: deleteDelivery))

            let manifest = ManifestEntity(context: context)
            manifest.manifestId = UUID().uuidString
            manifest.downloadedAt = now
            manifest.rawData = String(data: data, encoding: .utf8)
            manifest.status = "active"

            for item in deliveries {
                let entity = DeliveryEntity(context: context)
                entity.deliveryId = item.deliveryId
                entity.manifestId = manifest.manifestId
                entity.recipientName = item.recipientName
                entity.address1 = item.addressLine1
                entity.address2 = item.addressLine2
                entity.city = item.city
                entity.postcode = item.postcode
                entity.boxCount = Int32(item.boxCount)
                entity.weightKg = item.totalWeightKg
                entity.instructions = item.specialInstructions
                entity.status = item.status
            }

            try context.save()
        }

        // Merge background changes into the view context.
        await persistence.container.viewContext.perform {
            self.persistence.container.viewContext.refreshAllObjects()
        }
    }

    private func loadLastDownloadedAt() {
        let context = persistence.container.viewContext
        let fetch = NSFetchRequest<ManifestEntity>(entityName: "ManifestEntity")
        fetch.sortDescriptors = [NSSortDescriptor(keyPath: \ManifestEntity.downloadedAt, ascending: false)]
        fetch.fetchLimit = 1
        lastDownloadedAt = (try? context.fetch(fetch))?.first?.downloadedAt
    }

    static func hasManifest(context: NSManagedObjectContext) -> Bool {
        let fetch = NSFetchRequest<ManifestEntity>(entityName: "ManifestEntity")
        fetch.fetchLimit = 1
        return (try? context.count(for: fetch)) ?? 0 > 0
    }
}
