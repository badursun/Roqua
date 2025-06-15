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
    
    override init() {
        super.init()
        setupLocationManager()
        updatePermissionState()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10 metre hareket ettiğinde güncelle
        
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
    }
    
    private func updatePermissionState() {
        authorizationStatus = locationManager.authorizationStatus
        
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
    
    // MARK: - Permission Request Methods
    func requestWhenInUsePermission() {
        // Main thread blocking sorununu çöz
        Task { @MainActor in
            guard permissionState == .notRequested else { 
                print("⚠️ Permission already requested or granted")
                return 
            }
            
            guard CLLocationManager.locationServicesEnabled() else {
                print("❌ Location services disabled")
                permissionState = .denied
                return
            }
            
            print("📍 Requesting when in use permission...")
            permissionState = .requesting
            
            // Asenkron permission request
            DispatchQueue.main.async { [weak self] in
                self?.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func requestAlwaysPermission() {
        Task { @MainActor in
            guard permissionState == .whenInUseGranted else {
                print("⚠️ When in use permission required first")
                // Önce when in use izni alınmalı
                requestWhenInUsePermission()
                return
            }
            
            print("📍 Requesting always permission...")
            permissionState = .requesting
            
            // Asenkron permission request
            DispatchQueue.main.async { [weak self] in
                self?.locationManager.requestAlwaysAuthorization()
            }
        }
    }
    
    func startLocationUpdates() {
        guard permissionState == .alwaysGranted || permissionState == .whenInUseGranted else {
            print("❌ No location permission for updates")
            return
        }
        
        print("✅ Starting location updates")
        locationManager.startUpdatingLocation()
        
        // Background location için
        if permissionState == .alwaysGranted {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        }
    }
    
    func stopLocationUpdates() {
        print("⏹️ Stopping location updates")
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            currentLocation = location
            print("📍 New location: \(location.coordinate.latitude), \(location.coordinate.longitude), accuracy: ±\(location.horizontalAccuracy)m")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔄 Authorization changed to: \(status.rawValue)")
        
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
            
            // When In Use izni alındıktan sonra otomatik olarak always izni isteme
            // (Bu onboarding flow'da kontrol edilecek)
            if status == .authorizedWhenInUse && previousState == .requesting {
                print("ℹ️ When in use granted, ready for always permission request")
            }
        }
    }
} 