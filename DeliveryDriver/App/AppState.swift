import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    enum Route { case splash, login, main }

    @Published var route: Route = .splash

    private let keychain = KeychainService()

    func checkSession() {
        route = keychain.readToken() != nil ? .main : .login
    }

    func signOut() {
        keychain.deleteToken()
        LocationService.shared.stop()
        SyncService.shared.stop()
        route = .login
    }
}
