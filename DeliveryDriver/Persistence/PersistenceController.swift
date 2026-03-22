import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DeliveryDriver")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // Removes audit records (scans, PODs, locations) older than 14 days.
    func purgeExpiredRecords() {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) else { return }
        let context = container.newBackgroundContext()
        context.perform {
            let cutoffDate = cutoff as NSDate

            let scanFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ScanEntity")
            scanFetch.predicate = NSPredicate(format: "scannedAt < %@", cutoffDate)

            let podFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "PODEntity")
            podFetch.predicate = NSPredicate(format: "capturedAt < %@", cutoffDate)

            let locFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity")
            locFetch.predicate = NSPredicate(format: "recordedAt < %@", cutoffDate)

            for fetch in [scanFetch, podFetch, locFetch] {
                let batchDelete = NSBatchDeleteRequest(fetchRequest: fetch)
                batchDelete.resultType = .resultTypeObjectIDs
                if let result = try? context.execute(batchDelete) as? NSBatchDeleteResult,
                   let ids = result.result as? [NSManagedObjectID] {
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                        into: [self.container.viewContext]
                    )
                }
            }
        }
    }
}
