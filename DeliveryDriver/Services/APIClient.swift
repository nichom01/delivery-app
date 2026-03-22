import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noToken
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "The configured endpoint URL is invalid."
        case .noToken:              return "You are not signed in."
        case .httpError(let code):  return "Server error (HTTP \(code))."
        case .decodingError:        return "Unexpected response from the server."
        case .networkError(let e):  return e.localizedDescription
        case .unknown:              return "An unknown error occurred."
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let keychain = KeychainService()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Authentication

    func login(url: URL, username: String, password: String) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["username": username, "password": password])

        let (data, response) = try await perform(request)
        try validate(response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["token"] as? String else {
            throw APIError.decodingError(APIError.unknown)
        }
        return token
    }

    // MARK: - Manifest

    func fetchManifest(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        try attachAuth(to: &request)

        let (data, response) = try await perform(request)
        try validate(response)
        return data
    }

    // MARK: - Generic POST

    func post(url: URL, body: [String: Any]) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try attachAuth(to: &request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await perform(request)
        try validate(response)
    }

    // MARK: - Helpers

    private func attachAuth(to request: inout URLRequest) throws {
        guard let token = keychain.readToken() else { throw APIError.noToken }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }
        guard (200..<300).contains(http.statusCode) else { throw APIError.httpError(http.statusCode) }
    }
}
