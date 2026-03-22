import Foundation
import CoreData

// Seeds a realistic fake manifest + deliveries so every screen has data to show
// in demo mode. Safe to call multiple times — replaces existing records.
final class DemoDataService {
    static let shared = DemoDataService()
    private let persistence = PersistenceController.shared

    func seed() {
        let context = persistence.container.newBackgroundContext()
        context.perform {
            // Clear existing data first
            for entity in ["ManifestEntity", "DeliveryEntity"] {
                let req = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
                try? context.execute(NSBatchDeleteRequest(fetchRequest: req))
            }

            let manifest = ManifestEntity(context: context)
            manifest.manifestId = "DEMO-MANIFEST-001"
            manifest.downloadedAt = Date()
            manifest.status = "active"

            let deliveries: [(id: String, name: String, a1: String, city: String, pc: String, boxes: Int, kg: Double, instructions: String?, status: String)] = [
                ("DEL-001", "Sarah Mitchell",   "14 Oakwood Avenue",      "Manchester",  "M14 5EW",  3, 12.4, nil,                              "pending"),
                ("DEL-002", "James O'Brien",    "7 Riverside Close",      "Salford",     "M5 4WT",   1,  3.2, "Leave with neighbour if out.",    "pending"),
                ("DEL-003", "Priya Sharma",     "Flat 4, 22 High Street", "Stretford",   "M32 9BL",  2,  8.0, nil,                              "completed"),
                ("DEL-004", "Tom Wakefield",    "99 Birchwood Lane",      "Stockport",   "SK1 4QD",  5, 21.0, "Fragile — handle with care.",     "pending"),
                ("DEL-005", "Anita Kowalski",   "3 Station Road",         "Altrincham",  "WA14 1EP", 1,  1.5, nil,                              "pending"),
            ]

            for d in deliveries {
                let e = DeliveryEntity(context: context)
                e.deliveryId    = d.id
                e.manifestId    = manifest.manifestId
                e.recipientName = d.name
                e.address1      = d.a1
                e.city          = d.city
                e.postcode      = d.pc
                e.boxCount      = Int32(d.boxes)
                e.weightKg      = d.kg
                e.instructions  = d.instructions
                e.status        = d.status
            }

            try? context.save()
        }
    }
}
