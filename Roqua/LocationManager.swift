import Foundation
import CoreLocation
import SwiftUI

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
    @Published var permissionState: LocationPermissionState = .notRequested
    @Published var currentLocation: CLLocation?
    @Published var isLocationServicesEnabled = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private var permissionContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    
    override init() {
        super.init()
        setupLocationManager()
        updatePermissionState()
        
        // Mevcut izinleri kontrol et ve gerekirse location updates'i başlat
        checkExistingPermissions()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10 metre hareket ettiğinde güncelle
        
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
        print("📍 Location services enabled: \(isLocationServicesEnabled)")
    }
    
    private func updatePermissionState() {
        authorizationStatus = locationManager.authorizationStatus
        print("📍 Current authorization status: \(authorizationStatus.rawValue)")
        
        switch authorizationStatus {
        case .notDetermined:
            permissionState = .notRequested
        case .authorizedWhenInUse:
            permissionState = .whenInUseGranted
        case .authorizedAlways:
            permissionState = .alwaysGranted
        case .denied:
            permissionState = .denied
        case .restricted:
            permissionState = .restricted
        @unknown default:
            permissionState = .unknown
        }
    }
    
    private func checkExistingPermissions() {
        // Mevcut izin durumunu kontrol et
        switch authorizationStatus {
        case .authorizedAlways:
            print("✅ Always permission already granted - starting location updates")
            startLocationUpdates()
        case .authorizedWhenInUse:
            print("✅ When in use permission already granted")
        case .denied, .restricted:
            print("❌ Location permission denied or restricted")
        case .notDetermined:
            print("📍 Location permission not determined yet")
        @unknown default:
            print("⚠️ Unknown location permission state")
        }
    }
    
    // MARK: - Permission Request Methods
    func requestWhenInUsePermission() async {
        guard permissionState == .notRequested else { 
            print("⚠️ Permission already requested or granted: \(permissionState)")
            return 
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            print("❌ Location services disabled")
            permissionState = .denied
            return
        }
        
        print("📍 Requesting when in use permission...")
        permissionState = .requesting
        
        // iOS permission request - delegate callback bekle
        let status = await withCheckedContinuation { continuation in
            self.permissionContinuation = continuation
            
            // Main thread'de permission request - iOS requirement
            self.locationManager.requestWhenInUseAuthorization()
        }
        
        print("📍 Permission request completed with status: \(status.rawValue)")
    }
    
    func requestAlwaysPermission() async {
        // When in use permission kontrolü - ama recursive call yapma
        if permissionState != .whenInUseGranted {
            print("⚠️ When in use permission required first. Current state: \(permissionState)")
            return
        }
        
        print("📍 Requesting always permission...")
        permissionState = .requesting
        
        // iOS permission request - delegate callback bekle
        let status = await withCheckedContinuation { continuation in
            self.permissionContinuation = continuation
            
            // Main thread'de permission request - iOS requirement
            self.locationManager.requestAlwaysAuthorization()
        }
        
        print("📍 Always permission request completed with status: \(status.rawValue)")
    }
    
    func startLocationUpdates() {
        guard permissionState == .alwaysGranted || permissionState == .whenInUseGranted else {
            print("❌ No location permission for updates")
            return
        }
        
        print("✅ Starting location updates")
        
        // Background location için gerekli ayarlar - startUpdatingLocation'dan önce
        if permissionState == .alwaysGranted {
            // Background modes kontrolü - Info.plist'te location background mode var mı?
            if let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String],
               backgroundModes.contains("location") {
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.pausesLocationUpdatesAutomatically = false
                print("✅ Background location updates enabled")
            } else {
                print("⚠️ Background location mode not configured in Info.plist - continuing with foreground only")
            }
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        print("⏹️ Stopping location updates")
        locationManager.stopUpdatingLocation()
        
        // Background updates'i güvenli şekilde kapat
        if permissionState == .alwaysGranted {
            locationManager.allowsBackgroundLocationUpdates = false
        }
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
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            currentLocation = location
            print("📍 New location: \(location.coordinate.latitude), \(location.coordinate.longitude), accuracy: ±\(location.horizontalAccuracy)m")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        
        Task { @MainActor in
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
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔄 Authorization changed to: \(status.rawValue) (\(status.description))")
        
        Task { @MainActor in
            authorizationStatus = status
            
            // Önceki state'i sakla
            let previousState = permissionState
            
            // Yeni state'i güncelle
            switch status {
            case .notDetermined:
                permissionState = .notRequested
            case .authorizedWhenInUse:
                permissionState = .whenInUseGranted
                print("✅ When in use permission granted")
            case .authorizedAlways:
                permissionState = .alwaysGranted
                print("✅ Always permission granted")
                startLocationUpdates()
            case .denied:
                permissionState = .denied
                print("❌ Permission denied")
            case .restricted:
                permissionState = .restricted
                print("❌ Permission restricted")
            @unknown default:
                permissionState = .unknown
                print("⚠️ Unknown permission state")
            }
            
            // State değişimini log'la
            if previousState != permissionState {
                print("🔄 Permission state changed: \(previousState) → \(permissionState)")
            }
            
            // Continuation'ı resolve et
            if let continuation = permissionContinuation {
                permissionContinuation = nil
                continuation.resume(returning: status)
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