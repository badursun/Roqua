import Foundation
import CoreLocation
import SwiftUI
import Combine
import UIKit

// MARK: - Location Permission States
enum LocationPermissionState {
    case notRequested
    case requesting
    case whenInUseGranted
    case alwaysGranted
    case denied
    case restricted
    case unknown
}

// MARK: - Location Manager
@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var significantLocationChange: CLLocation?
    @Published var permissionState: LocationPermissionState = .notRequested
    @Published var isTracking: Bool = false
    
    private let locationManager = CLLocationManager()
    private let eventBus = EventBus.shared
    private let settings = AppSettings.shared
    
    private var lastProcessedLocation: CLLocation?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    override init() {
        super.init()
        setupLocationManager()
        setupAppStateNotifications()
    }
    
    private func setupAppStateNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppStateChange(isActive: true)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppStateChange(isActive: false)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMemoryWarning()
            }
        }
    }
    
    private func handleAppStateChange(isActive: Bool) {
        guard isTracking else { return }
        
        print("📱 App state changed: \(isActive ? "Active" : "Background")")
        configureLocationAccuracy()
        
        if isActive {
            endBackgroundTask()
        } else {
            startBackgroundTask()
        }
    }
    
    private func startBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "LocationProcessing") { [weak self] in
            self?.endBackgroundTask()
        }
        
        print("🔄 Background task started: \(backgroundTask.rawValue)")
    }
    
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        
        print("⏹️ Ending background task: \(backgroundTask.rawValue)")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    private func handleMemoryWarning() {
        print("⚠️ Memory warning received - reducing accuracy")
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        locationManager.distanceFilter = 200.0
    }
    
    deinit {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0 // 10m minimum hareket - daha hızlı UI güncellemesi
        
        // Background location updates için gerekli
        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            print("📍 Background location updates enabled")
        }
        
        print("📍 Setting up location manager...")
    }
    

    
    // MARK: - Permission Request Methods
    @MainActor
    func checkLocationPermission() {
        print("📍 Checking location permission...")
        
        let status = locationManager.authorizationStatus
        print("📍 Current authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            print("📍 Requesting location permission...")
            locationManager.requestAlwaysAuthorization()
            
        case .denied, .restricted:
            print("❌ Location permission denied or restricted")
            permissionState = .denied
            
        case .authorizedWhenInUse:
            print("⚠️ Only 'When In Use' permission granted, requesting 'Always'...")
            locationManager.requestAlwaysAuthorization()
            permissionState = .whenInUseGranted
            
        case .authorizedAlways:
            print("✅ Always permission granted")
            permissionState = .alwaysGranted
            startLocationUpdates()
            
        @unknown default:
            print("❓ Unknown authorization status")
            permissionState = .denied
        }
    }
    
    @MainActor
    func startLocationUpdates() {
        print("✅ Starting location updates")
        
        // App state'e göre accuracy ayarla
        configureLocationAccuracy()
        
        locationManager.startUpdatingLocation()
        
        // Significant location changes her zaman başlat (background için kritik)
        locationManager.startMonitoringSignificantLocationChanges()
        print("🔄 Started both regular and significant location monitoring")
        
        isTracking = true
        
        // Event publish et
        eventBus.publish(locationEvent: .locationTrackingStarted)
    }
    
    private func configureLocationAccuracy() {
        let appState = UIApplication.shared.applicationState
        
        if appState == .active {
            // Foreground: Yüksek doğruluk
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 10.0
            print("📍 Foreground accuracy: Best (10m filter)")
        } else {
            // Background: Düşük doğruluk, pil tasarrufu
            locationManager.desiredAccuracy = kCLLocationAccuracyReduced
            locationManager.distanceFilter = 100.0
            print("📍 Background accuracy: Reduced (100m filter)")
        }
    }
    
    func stopLocationUpdates() {
        print("⏹️ Stopping location updates")
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        isTracking = false
        
        // Publish location tracking stopped event
        eventBus.publish(locationEvent: .locationTrackingStopped)
    }
    
    // MARK: - Helper Methods
    var canRequestAlwaysPermission: Bool {
        return permissionState == .whenInUseGranted
    }
    
    var isFullyAuthorized: Bool {
        return permissionState == .alwaysGranted
    }
    
    var needsPermission: Bool {
        return permissionState == .notRequested || permissionState == .denied
    }
    
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        Task { @MainActor in
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func requestWhenInUsePermission() async {
        print("📍 Requesting when in use permission...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysPermission() async {
        print("📍 Requesting always permission...")
        locationManager.requestAlwaysAuthorization()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("📱 RAW LOCATION UPDATE: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude)) - accuracy: \(Int(location.horizontalAccuracy))m")
        
        Task { @MainActor in
            // Her zaman currentLocation'ı güncelle (UI için) - hızlı güncelleme
            currentLocation = location
            
            // Konum değişikliği kontrolü - sadece significant changes için
            let shouldProcess = shouldProcessLocation(location)
            print("🔄 Should process location: \(shouldProcess)")
            
            if shouldProcess {
                lastProcessedLocation = location
                significantLocationChange = location
                
                // Publish significant location change event
                eventBus.publish(locationEvent: .significantLocationChange(location))
                
                print("📍 Significant location: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude)), ±\(Int(location.horizontalAccuracy))m")
            }
        }
    }
    
    private func shouldProcessLocation(_ location: CLLocation) -> Bool {
        let appState = UIApplication.shared.applicationState
        print("🔍 SHOULD PROCESS CHECK:")
        print("  - backgroundLocationEnabled: \(settings.backgroundLocationEnabled)")
        print("  - appState: \(appState.rawValue)")
        print("  - accuracy: \(location.horizontalAccuracy)m vs threshold: \(settings.accuracyThreshold)m")
        
        // Accuracy kontrolü - her durumda geçerli olmalı
        guard location.horizontalAccuracy <= settings.accuracyThreshold && location.horizontalAccuracy > 0 else {
            print("🚫 Accuracy too low: \(location.horizontalAccuracy)m > \(settings.accuracyThreshold)m")
            return false
        }
        
        // Distance kontrolü
        let shouldProcessByDistance: Bool
        if let lastLocation = lastProcessedLocation {
            let distance = location.distance(from: lastLocation)
            let threshold = appState == .active ? settings.locationTrackingDistance : 100.0 // Background'da daha büyük threshold
            print("  - distance from last: \(distance)m vs threshold: \(threshold)m")
            shouldProcessByDistance = distance >= threshold
        } else {
            shouldProcessByDistance = true // İlk konum her zaman işlenir
        }
        
        // Background'da heavy processing'i kısıtla, basic recording'i değil
        if appState != .active && !settings.backgroundLocationEnabled {
            print("🔄 Background mode: Basic recording only (heavy processing disabled)")
            // Konum kaydını durdurma, sadece heavy processing'i (POI enrichment vs) durdur
            // Basic location recording her zaman devam etmeli
        }
        
        return shouldProcessByDistance
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        
        Task { @MainActor in
            // Publish location error event
            eventBus.publish(locationEvent: .locationError(error))
            
            // Location error handling
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    permissionState = .denied
                case .locationUnknown:
                    print("⚠️ Location temporarily unavailable")
                case .network:
                    print("⚠️ Network error")
                default:
                    print("⚠️ Other location error: \(clError.localizedDescription)")
                }
            }
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            print("🔄 Authorization changed to: \(status.rawValue) (\(status.description))")
            
            switch status {
            case .notDetermined:
                permissionState = .notRequested
                
            case .denied, .restricted:
                permissionState = .denied
                eventBus.publish(locationEvent: .permissionDenied)
                
            case .authorizedWhenInUse:
                permissionState = .whenInUseGranted
                eventBus.publish(locationEvent: .permissionGranted(.whenInUse))
                
            case .authorizedAlways:
                permissionState = .alwaysGranted
                eventBus.publish(locationEvent: .permissionGranted(.always))
                startLocationUpdates()
                
            @unknown default:
                permissionState = .denied
            }
        }
    }
}

// MARK: - CLAuthorizationStatus Extension
extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
    }
} 