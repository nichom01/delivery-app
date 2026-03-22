import Foundation
import CoreData

final class SyncService: ObservableObject {
    static let shared = SyncService()

    private var timer: Timer?
    private let api = APIClient.shared
    private let persistence = PersistenceController.shared
    private var settings: SettingsStore { SettingsStore.shared }

    func start() {
        guard settings.transmissionEnabled else { return }
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restartIfEnabled() {
        stop()
        start()
    }

    func syncNow() {
        Task { await sync() }
    }

    // MARK: - Private

    private func scheduleTimer() {
        timer?.invalidate()
        let interval = TimeInterval(max(settings.transmissionFrequency, 10))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.sync() }
        }
    }

    private func sync() async {
        await syncLocations()
        await syncPODs()
        await syncScans()
    }

    // MARK: - Location sync

    private func syncLocations() async {
        guard let url = settings.submissionURL else { return }
        let context = persistence.container.newBackgroundContext()

        let records: [LocationEntity] = await context.perform {
            let fetch = NSFetchRequest<LocationEntity>(entityName: "LocationEntity")
            fetch.predicate = NSPredicate(format: "submittedAt == nil")
            return (try? context.fetch(fetch)) ?? []
        }
        guard !records.isEmpty else { return }

        let iso = ISO8601DateFormatter()
        let payload: [[String: Any]] = await context.perform {
            records.map {[
                "type": "location",
                "latitude": $0.latitude,
                "longitude": $0.longitude,
                "recorded_at": iso.string(from: $0.recordedAt ?? Date())
            ]}
        }

        do {
            try await api.post(url: url, body: ["events": payload])
            await context.perform {
                let now = Date()
                records.forEach { $0.submittedAt = now }
                try? context.save()
            }
        } catch {}
    }

    // MARK: - POD sync

    private func syncPODs() async {
        guard let url = settings.submissionURL else { return }
        let context = persistence.container.newBackgroundContext()

        let records: [PODEntity] = await context.perform {
            let fetch = NSFetchRequest<PODEntity>(entityName: "PODEntity")
            fetch.predicate = NSPredicate(format: "submittedAt == nil")
            return (try? context.fetch(fetch)) ?? []
        }
        guard !records.isEmpty else { return }

        let iso = ISO8601DateFormatter()
        do {
            for pod in records {
                let body: [String: Any] = await context.perform {
                    var payload: [String: Any] = [
                        "type": "pod",
                        "delivery_id": pod.deliveryId ?? "",
                        "recipient_name": pod.recipientName ?? "",
                        "signature": pod.signatureImage?.base64EncodedString() ?? "",
                        "captured_at": iso.string(from: pod.capturedAt ?? Date())
                    ]
                    if let photo = pod.photoImage {
                        payload["photo"] = photo.base64EncodedString()
                    }
                    return payload
                }
                try await api.post(url: url, body: body)
                await context.perform {
                    pod.submittedAt = Date()
                    try? context.save()
                }
            }
        } catch {}
    }

    // MARK: - Scan sync

    private func syncScans() async {
        guard let url = settings.loadURL else { return }
        let context = persistence.container.newBackgroundContext()

        let records: [ScanEntity] = await context.perform {
            let fetch = NSFetchRequest<ScanEntity>(entityName: "ScanEntity")
            fetch.predicate = NSPredicate(format: "submittedAt == nil")
            return (try? context.fetch(fetch)) ?? []
        }
        guard !records.isEmpty else { return }

        let iso = ISO8601DateFormatter()
        do {
            for scan in records {
                let body: [String: Any] = await context.perform {[
                    "type": "scan",
                    "barcode_value": scan.barcodeValue ?? "",
                    "delivery_id": scan.deliveryId ?? "",
                    "scanned_at": iso.string(from: scan.scannedAt ?? Date())
                ]}
                try await api.post(url: url, body: body)
                await context.perform {
                    scan.submittedAt = Date()
                    try? context.save()
                }
            }
        } catch {}
    }
}
