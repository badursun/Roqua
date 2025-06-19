import Foundation
import CoreLocation
import SwiftUI
import Combine
import UIKit
import BackgroundTasks

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
        registerBackgroundTasks()
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
        print("⚠️ Memory warning received - reducing accuracy and increasing distance filter")
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        locationManager.distanceFilter = 200.0  // Memory pressure durumunda fallback
        print("📍 Memory warning fallback: Reduced accuracy (200m filter)")
    }
    
    // MARK: - Background Task Registration
    private func registerBackgroundTasks() {
        // Info.plist'teki BGTaskSchedulerPermittedIdentifiers ile eşleşen identifier
        let identifier = "com.adjans.roqua.background-location"
        
        let success = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            self.handleBackgroundLocationTask(task: task as! BGProcessingTask)
        }
        
        if success {
            print("✅ BGTaskScheduler registered successfully for: \(identifier)")
        } else {
            print("❌ Failed to register BGTaskScheduler for: \(identifier)")
        }
    }
    
    private func handleBackgroundLocationTask(task: BGProcessingTask) {
        print("🔄 Background location task started")
        
        // Task timeout handler
        task.expirationHandler = {
            print("⏰ Background task expiring")
            task.setTaskCompleted(success: false)
        }
        
        // Location işlemlerini burada yapabilirsin
        // Örneğin: Lokasyon güncellemelerini işle, cache'i temizle vs.
        
        // Task başarıyla tamamlandı
        task.setTaskCompleted(success: true)
        print("✅ Background location task completed")
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
            // Background: Optimize edilmiş doğruluk, pil tasarrufu
            locationManager.desiredAccuracy = kCLLocationAccuracyReduced
            locationManager.distanceFilter = 20.0  // 100m'den 20m'ye optimize edildi
            print("📍 Background accuracy: Reduced (20m filter) - Optimized for better tracking")
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
    
    @MainActor
    func requestImmediateLocation() {
        print("🎯 Requesting immediate location for startup...")
        locationManager.requestLocation()
    }
    
    @MainActor
    func requestFreshLocation() {
        print("🔄 Requesting fresh location update...")
        // Mevcut cache'i temizle ve fresh location iste
        currentLocation = nil
        locationManager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("📱 RAW LOCATION UPDATE: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude)) - accuracy: \(Int(location.horizontalAccuracy))m")
        
        Task { @MainActor in
            // 🔧 FIX: currentLocation'ı sadece reasonable accuracy'li location'larla güncelle
            let accuracyThreshold: Double = 100.0 // UI için accuracy threshold
            let isAccurate = location.horizontalAccuracy > 0 && location.horizontalAccuracy <= accuracyThreshold
            
            if isAccurate {
                // Sadece doğru accuracy'li location'ları currentLocation'a set et
                currentLocation = location
                print("✅ CURRENT LOCATION UPDATED: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude)) (accuracy: \(Int(location.horizontalAccuracy))m)")
            } else {
                print("🚫 CURRENT LOCATION NOT UPDATED: accuracy \(Int(location.horizontalAccuracy))m > \(accuracyThreshold)m")
            }
            
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
        
        // Accuracy kontrolü - background vs foreground farklı threshold
        // İlk konum için (lastProcessedLocation == nil) daha relaxed threshold
        let accuracyThreshold: Double
        if appState == .active {
            // Foreground: İlk konum için 5km (GPS startup için), sonraki konumlar için normal threshold
            accuracyThreshold = lastProcessedLocation == nil ? 5000.0 : settings.accuracyThreshold
        } else {
            // Background: Her zaman 1km threshold
            accuracyThreshold = 1000.0
        }
        
        guard location.horizontalAccuracy <= accuracyThreshold && location.horizontalAccuracy > 0 else {
            let thresholdType = appState == .active ? (lastProcessedLocation == nil ? "foreground-initial-5km" : "foreground") : "background"
            print("🚫 Accuracy too low: \(location.horizontalAccuracy)m > \(accuracyThreshold)m (threshold for \(thresholdType))")
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
                    print("⚠️ Location temporarily unavailable - will retry with significant changes")
                case .network:
                    print("⚠️ Network error - falling back to cached location if available")
                case .locationUnknown:
                    print("🎯 Immediate location request failed - continuing with regular updates")
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
            // Always permission'da otomatik başlat
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