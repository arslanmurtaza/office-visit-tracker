import Foundation
import CoreLocation
import SwiftData
import Combine

/// Central location manager: handles authorization, region monitoring, and visit recording.
/// When the device enters/exits a monitored region (a circle around a saved office), the app
/// is woken up (or continues in the background) and records a `Visit` without the user opening the app.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?
    @Published var isMonitoring: Bool = false
    @Published var monitoredPlaceIds: Set<UUID> = []
    @Published var lastVisitReceived: Date?

    private let locationManager = CLLocationManager()
    private var modelContext: ModelContext?
    private var anyCancellable = Set<AnyCancellable>()

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        requestAuthorization()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Authorization

    func requestAuthorization() {
        // "Always" is required so the app can track visits when it's not in the foreground
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Region monitoring

    /// Start monitoring a region around the given place. iOS will wake the app when the device
    /// crosses the region boundary, even if the app is backgrounded or killed.
    func startMonitoring(placeId: UUID) {
        guard let place = fetchPlace(id: placeId) else { return }

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
            radius: 100, // ~100 m radius
            identifier: place.id.uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true

        locationManager.startMonitoring(for: region)
        monitoredPlaceIds.insert(placeId)
        isMonitoring = true

        // Keep updating location so we can also show the user's current position
        locationManager.startUpdatingLocation()
    }

    func stopMonitoring(placeId: UUID) {
        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == placeId.uuidString }) {
            locationManager.stopMonitoring(for: region)
        }
        monitoredPlaceIds.remove(placeId)
        if monitoredPlaceIds.isEmpty {
            isMonitoring = false
        }
        locationManager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        Task { @MainActor in
            if let place = self.fetchPlace(id: UUID(uuidString: circularRegion.identifier ?? "")) {
                self.recordVisitArrived(for: place)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        Task { @MainActor in
            if let place = self.fetchPlace(id: UUID(uuidString: circularRegion.identifier ?? "")) {
                self.recordVisitDeparted(for: place)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    // MARK: - Visit recording

    private func recordVisitArrived(for place: Place) {
        let fetch = FetchDescriptor<Visit>(
            predicate: #Predicate<Visit> { $0.placeId == place.id && $0.status == .active }
        )
        if let existing = try? modelContext?.fetch(fetch).first {
            // Arrived while already tracking this place — ignore duplicate entry
            return
        }
        let visit = Visit(placeId: place.id, arrivedAt: Date(), status: .active)
        modelContext?.insert(visit)
        try? modelContext?.save()
        lastVisitReceived = Date()
        self.notifyUser(place: place)
    }

    private func recordVisitDeparted(for place: Place) {
        let fetch = FetchDescriptor<Visit>(
            predicate: #Predicate<Visit> { $0.placeId == place.id && $0.status == .active }
        )
        if let visit = try? modelContext?.fetch(fetch).first {
            visit.leftAt = Date()
            visit.durationSeconds = Int(Date().timeIntervalSince(visit.arrivedAt))
            visit.status = .completed
            try? modelContext?.save()
        }
    }

    // MARK: - Helpers

    private func fetchPlace(id: UUID) -> Place? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<Place>(predicate: #Predicate<Place> { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    private func notifyUser(place: Place) {
        // Local notification when the user enters the monitored region
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Visit Detected"
        content.body = "\(place.name) — you've arrived."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            center.add(request)
        }
    }
}
