import Foundation
import CoreData

@MainActor
final class LoadViewModel: ObservableObject {
    @Published var hasManifest = false
    @Published var isScanning = true
    @Published var scannedValue: String?
    @Published var confirmedScan: ScanConfirmation?
    @Published var errorMessage: String?
    @Published var manualEntry = ""

    private let persistence = PersistenceController.shared

    struct ScanConfirmation {
        let barcodeValue: String
        let timestamp: Date
    }

    func checkManifest() {
        let context = persistence.container.viewContext
        let fetch = NSFetchRequest<ManifestEntity>(entityName: "ManifestEntity")
        fetch.fetchLimit = 1
        hasManifest = (try? context.count(for: fetch)) ?? 0 > 0
    }

    func handleScan(_ value: String) {
        isScanning = false
        save(barcodeValue: value)
    }

    func submitManualEntry() {
        let trimmed = manualEntry.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a barcode value."
            return
        }
        save(barcodeValue: trimmed)
        manualEntry = ""
    }

    func resumeScanning() {
        confirmedScan = nil
        errorMessage = nil
        isScanning = true
    }

    // MARK: - Private

    private func save(barcodeValue: String) {
        let context = persistence.container.newBackgroundContext()
        let now = Date()

        // Resolve the current manifest id on the background context.
        context.perform {
            let manifestFetch = NSFetchRequest<ManifestEntity>(entityName: "ManifestEntity")
            manifestFetch.sortDescriptors = [NSSortDescriptor(keyPath: \ManifestEntity.downloadedAt, ascending: false)]
            manifestFetch.fetchLimit = 1
            let manifestId = (try? context.fetch(manifestFetch))?.first?.manifestId

            let entity = ScanEntity(context: context)
            entity.scanId = UUID().uuidString
            entity.barcodeValue = barcodeValue
            entity.deliveryId = manifestId   // links scan to manifest; updated to delivery when matched
            entity.scannedAt = now
            try? context.save()

            DispatchQueue.main.async {
                self.confirmedScan = ScanConfirmation(barcodeValue: barcodeValue, timestamp: now)
            }
        }
    }
}
