import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIClient.shared
    private let keychain = KeychainService()
    private let settings: SettingsStore = .shared

    func loginAsDemo(onSuccess: @escaping () -> Void) {
        keychain.save(token: "demo-token")
        DemoDataService.shared.seed()
        onSuccess()
    }

    func login(onSuccess: @escaping () -> Void) async {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            errorMessage = "Please enter your username and password."
            return
        }
        guard let url = settings.loginURL else {
            errorMessage = "Login URL is not configured. Go to Settings and add the API endpoint."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let token = try await api.login(url: url, username: username, password: password)
            keychain.save(token: token)
            onSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
