import Foundation
import CoreLocation
import UIKit

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private let persistence = PersistenceController.shared
    private var recordingTimer: Timer?
    private var latestLocation: CLLocation?
    private var lastRecordedAt: Date?

    private var settings: SettingsStore { SettingsStore.shared }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Lifecycle

    /// Called when the app becomes active / enters foreground.
    func start() {
        guard settings.locationEnabled else { return }
        manager.requestAlwaysAuthorization()
        manager.stopMonitoringSignificantLocationChanges()
        manager.startUpdatingLocation()
        scheduleRecordingTimer()
    }

    /// Called when settings disable location or the user signs out.
    func stop() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    func restartIfEnabled() {
        stop()
        start()
    }

    /// Called when the app moves to background.
    /// Cancels the foreground timer; continuous location updates keep running via
    /// `allowsBackgroundLocationUpdates`. Significant-change monitoring acts as a
    /// safety net to relaunch the app if the OS terminates it.
    func enterBackground() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        if settings.locationEnabled {
            manager.startMonitoringSignificantLocationChanges()
        }
    }

    /// Called when the app returns to foreground after being backgrounded.
    func enterForeground() {
        guard settings.locationEnabled else { return }
        manager.stopMonitoringSignificantLocationChanges()
        manager.startUpdatingLocation()
        scheduleRecordingTimer()
    }

    // MARK: - Private

    private func scheduleRecordingTimer() {
        recordingTimer?.invalidate()
        let interval = TimeInterval(max(settings.locationFrequency, 5))
        recordingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.recordCurrentLocation() }
        }
    }

    /// Background-safe recording: saves a point if at least `locationFrequency`
    /// seconds have elapsed since the last save. Used when the foreground timer
    /// is not running.
    private func recordIfDue() {
        let interval = TimeInterval(max(settings.locationFrequency, 5))
        if let last = lastRecordedAt, Date().timeIntervalSince(last) < interval { return }
        recordCurrentLocation()
    }

    private func recordCurrentLocation() {
        guard let location = latestLocation else { return }
        lastRecordedAt = Date()
        let context = persistence.container.newBackgroundContext()
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let now = Date()
        context.perform {
            let entity = LocationEntity(context: context)
            entity.locationId = UUID().uuidString
            entity.latitude = lat
            entity.longitude = lon
            entity.recordedAt = now
            try? context.save()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.latestLocation = locations.last
            // When the foreground timer is not running (i.e. app is backgrounded),
            // record using the time-based gate instead.
            if self.recordingTimer == nil {
                self.recordIfDue()
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
            manager.startUpdatingLocation()
            if self.recordingTimer == nil {
                self.scheduleRecordingTimer()
            }
        }
    }
}
