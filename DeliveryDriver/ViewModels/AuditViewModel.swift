import Foundation
import CoreData

struct AuditEvent: Identifiable {
    enum EventType {
        case scan, pod, location

        var icon: String {
            switch self {
            case .scan:     return "barcode"
            case .pod:      return "checkmark.seal.fill"
            case .location: return "location.fill"
            }
        }
        var label: String {
            switch self {
            case .scan:     return "Scan"
            case .pod:      return "POD"
            case .location: return "Location"
            }
        }
        var accentColor: String {
            switch self {
            case .scan:     return "#FF6B35"
            case .pod:      return "#4CAF50"
            case .location: return "#2196F3"
            }
        }
    }

    let id: String
    let type: EventType
    let description: String
    let timestamp: Date
    let submittedAt: Date?

    var isPending: Bool { submittedAt == nil }
}

@MainActor
final class AuditViewModel: ObservableObject {
    @Published var events: [AuditEvent] = []
    @Published var filter: AuditFilter = .all

    enum AuditFilter: String, CaseIterable {
        case all     = "All"
        case pending = "Pending"
        case sent    = "Sent"
    }

    var filteredEvents: [AuditEvent] {
        switch filter {
        case .all:     return events
        case .pending: return events.filter { $0.isPending }
        case .sent:    return events.filter { !$0.isPending }
        }
    }

    private let persistence = PersistenceController.shared

    func loadEvents() {
        let context = persistence.container.viewContext
        var all: [AuditEvent] = []

        // Scans
        let scanFetch = NSFetchRequest<ScanEntity>(entityName: "ScanEntity")
        scanFetch.sortDescriptors = [NSSortDescriptor(keyPath: \ScanEntity.scannedAt, ascending: false)]
        if let scans = try? context.fetch(scanFetch) {
            all += scans.map {
                AuditEvent(
                    id: $0.scanId ?? UUID().uuidString,
                    type: .scan,
                    description: "Scanned \($0.barcodeValue ?? "—")",
                    timestamp: $0.scannedAt ?? Date(),
                    submittedAt: $0.submittedAt
                )
            }
        }

        // PODs
        let podFetch = NSFetchRequest<PODEntity>(entityName: "PODEntity")
        podFetch.sortDescriptors = [NSSortDescriptor(keyPath: \PODEntity.capturedAt, ascending: false)]
        if let pods = try? context.fetch(podFetch) {
            all += pods.map {
                AuditEvent(
                    id: $0.podId ?? UUID().uuidString,
                    type: .pod,
                    description: "POD for \($0.recipientName ?? "—")",
                    timestamp: $0.capturedAt ?? Date(),
                    submittedAt: $0.submittedAt
                )
            }
        }

        // Locations
        let locFetch = NSFetchRequest<LocationEntity>(entityName: "LocationEntity")
        locFetch.sortDescriptors = [NSSortDescriptor(keyPath: \LocationEntity.recordedAt, ascending: false)]
        if let locs = try? context.fetch(locFetch) {
            all += locs.map {
                AuditEvent(
                    id: $0.locationId ?? UUID().uuidString,
                    type: .location,
                    description: String(format: "%.5f, %.5f", $0.latitude, $0.longitude),
                    timestamp: $0.recordedAt ?? Date(),
                    submittedAt: $0.submittedAt
                )
            }
        }

        events = all.sorted { $0.timestamp > $1.timestamp }
    }
}
