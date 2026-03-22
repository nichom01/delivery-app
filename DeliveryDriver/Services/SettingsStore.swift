import Foundation
import Combine

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var locationFrequency: Int
    @Published var locationEnabled: Bool
    @Published var transmissionFrequency: Int
    @Published var transmissionEnabled: Bool
    @Published var loginEndpoint: String
    @Published var loadEndpoint: String
    @Published var manifestEndpoint: String
    @Published var submissionEndpoint: String

    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    init() {
        defaults.register(defaults: [
            "locationFrequency": 30,
            "locationEnabled": true,
            "transmissionFrequency": 60,
            "transmissionEnabled": true
        ])

        locationFrequency = defaults.integer(forKey: "locationFrequency")
        locationEnabled = defaults.bool(forKey: "locationEnabled")
        transmissionFrequency = defaults.integer(forKey: "transmissionFrequency")
        transmissionEnabled = defaults.bool(forKey: "transmissionEnabled")
        loginEndpoint = defaults.string(forKey: "loginEndpoint") ?? ""
        loadEndpoint = defaults.string(forKey: "loadEndpoint") ?? ""
        manifestEndpoint = defaults.string(forKey: "manifestEndpoint") ?? ""
        submissionEndpoint = defaults.string(forKey: "submissionEndpoint") ?? ""

        bindToDefaults()
    }

    var loginURL: URL? { URL(string: loginEndpoint) }
    var loadURL: URL? { URL(string: loadEndpoint) }
    var manifestURL: URL? { URL(string: manifestEndpoint) }
    var submissionURL: URL? { URL(string: submissionEndpoint) }

    private func bindToDefaults() {
        $locationFrequency
            .sink { [weak self] in self?.defaults.set($0, forKey: "locationFrequency") }
            .store(in: &cancellables)
        $locationEnabled
            .sink { [weak self] in self?.defaults.set($0, forKey: "locationEnabled") }
            .store(in: &cancellables)
        $transmissionFrequency
            .sink { [weak self] in self?.defaults.set($0, forKey: "transmissionFrequency") }
            .store(in: &cancellables)
        $transmissionEnabled
            .sink { [weak self] in self?.defaults.set($0, forKey: "transmissionEnabled") }
            .store(in: &cancellables)
        $loginEndpoint
            .sink { [weak self] in self?.defaults.set($0, forKey: "loginEndpoint") }
            .store(in: &cancellables)
        $loadEndpoint
            .sink { [weak self] in self?.defaults.set($0, forKey: "loadEndpoint") }
            .store(in: &cancellables)
        $manifestEndpoint
            .sink { [weak self] in self?.defaults.set($0, forKey: "manifestEndpoint") }
            .store(in: &cancellables)
        $submissionEndpoint
            .sink { [weak self] in self?.defaults.set($0, forKey: "submissionEndpoint") }
            .store(in: &cancellables)
    }
}
