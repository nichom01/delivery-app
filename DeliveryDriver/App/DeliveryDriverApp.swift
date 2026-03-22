import SwiftUI

@main
struct DeliveryDriverApp: App {
    let persistence = PersistenceController.shared
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(appState)
                .onAppear {
                    persistence.purgeExpiredRecords()
                }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                // Returning to foreground: resume full GPS tracking and sync timer.
                LocationService.shared.enterForeground()
                SyncService.shared.restartIfEnabled()

            case .background:
                // Moving to background: drop the foreground timer, start significant-
                // change monitoring so the OS can relaunch the app if terminated.
                LocationService.shared.enterBackground()
                // Attempt a final sync pass before execution time is curtailed.
                SyncService.shared.syncNow()

            case .inactive:
                break

            @unknown default:
                break
            }
        }
    }
}
