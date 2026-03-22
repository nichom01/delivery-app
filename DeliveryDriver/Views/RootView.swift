import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.route {
            case .splash: SplashView()
            case .login:  LoginView()
            case .main:   MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.route)
    }
}
