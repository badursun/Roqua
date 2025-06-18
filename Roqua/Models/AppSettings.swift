import Foundation
import SwiftUI

// MARK: - App Settings Model
@MainActor
class AppSettings: ObservableObject {
    
    // MARK: - Location Tracking Settings
    @AppStorage("locationTrackingDistance") var locationTrackingDistance: Double = 50.0 // meters
    @AppStorage("autoMapCentering") var autoMapCentering: Bool = true
    @AppStorage("preserveZoomPan") var preserveZoomPan: Bool = true
    
    // MARK: - Exploration Settings
    @AppStorage("explorationRadius") var explorationRadius: Double = 100.0 // meters - PRD'ye göre 100m
    @AppStorage("accuracyThreshold") var accuracyThreshold: Double = 50.0 // meters - default 50m
    @AppStorage("clusteringRadius") var clusteringRadius: Double =  50.0 // meters - exploration radius'un yarısı
    
    // MARK: - Appearance Settings  
    @AppStorage("colorScheme") var colorScheme: Int = 0 // 0: System, 1: Light, 2: Dark
    
    // MARK: - Map Settings
    @AppStorage("mapType") var mapType: Int = 0 // 0: Standard, 1: Satellite, 2: Hybrid
    @AppStorage("showUserLocation") var showUserLocation: Bool = true
    @AppStorage("enablePitch") var enablePitch: Bool = false
    @AppStorage("enableRotation") var enableRotation: Bool = false
    
    // MARK: - Privacy Settings
    @AppStorage("enableGeocoding") var enableGeocoding: Bool = true
    @AppStorage("offlineMode") var offlineMode: Bool = false
    
    // MARK: - Performance Settings
    @AppStorage("maxRegionsInMemory") var maxRegionsInMemory: Int = 1000
    @AppStorage("backgroundLocationEnabled") var backgroundLocationEnabled: Bool = true
    
    // MARK: - Grid & Exploration Settings
    @AppStorage("percentageDecimals") var percentageDecimals: Int = 9 // 0.000000001% precision (highest)
    @AppStorage("enableExplorationStats") var enableExplorationStats: Bool = true
    
    // MARK: - Reverse Geocoding Settings
    @AppStorage("enableReverseGeocoding") var enableReverseGeocoding: Bool = true
    @AppStorage("autoEnrichNewRegions") var autoEnrichNewRegions: Bool = true
    @AppStorage("batchEnrichOnStartup") var batchEnrichOnStartup: Bool = false
    @AppStorage("enableAutoEnrichment") var enableAutoEnrichment: Bool = true
    @AppStorage("enableBulkProcessOnLaunch") var enableBulkProcessOnLaunch: Bool = false
    
    // MARK: - Singleton
    static let shared = AppSettings()
    
    private init() {}
    
    // MARK: - Predefined Options
    struct TrackingDistanceOption {
        let value: Double
        let label: String
        let description: String
    }
    
    static let trackingDistanceOptions: [TrackingDistanceOption] = [
        TrackingDistanceOption(value: 25.0, label: "25m", description: "Çok hassas - daha fazla detay"),
        TrackingDistanceOption(value: 50.0, label: "50m", description: "Hassas - önerilen"),
        TrackingDistanceOption(value: 100.0, label: "100m", description: "Normal - batarya dostu"),
        TrackingDistanceOption(value: 200.0, label: "200m", description: "Geniş - uzun mesafe")
    ]
    
    struct RadiusOption {
        let value: Double
        let label: String
        let description: String
    }
    
    static let radiusOptions: [RadiusOption] = [
        RadiusOption(value: 100.0, label: "100m", description: "Küçük - yürüyüş için ideal"),
        RadiusOption(value: 200.0, label: "200m", description: "Orta - genel kullanım"),
        RadiusOption(value: 500.0, label: "500m", description: "Büyük - araç kullanımı")
    ]
    
    static let accuracyOptions: [RadiusOption] = [
        RadiusOption(value: 50.0, label: "50m", description: "Yüksek doğruluk"),
        RadiusOption(value: 100.0, label: "100m", description: "Normal doğruluk"),
        RadiusOption(value: 200.0, label: "200m", description: "Düşük doğruluk - batarya dostu")
    ]
    
    static let clusteringOptions: [RadiusOption] = [
        RadiusOption(value: 25.0, label: "25m", description: "Hassas gruplandırma"),
        RadiusOption(value: 50.0, label: "50m", description: "Normal gruplandırma"),
        RadiusOption(value: 100.0, label: "100m", description: "Geniş gruplandırma")
    ]
    
    // MARK: - Helper Methods
    func resetToDefaults() {
        locationTrackingDistance = 50.0
        autoMapCentering = true
        preserveZoomPan = true
        explorationRadius = 100.0
        accuracyThreshold = 50.0
        clusteringRadius = 50.0
        colorScheme = 0
        mapType = 0
        showUserLocation = true
        enablePitch = false
        enableRotation = false
        enableGeocoding = true
        offlineMode = false
        maxRegionsInMemory = 1000
        backgroundLocationEnabled = true
        percentageDecimals = 9
        enableExplorationStats = true
        
        // Reverse Geocoding defaults
        enableReverseGeocoding = true
        autoEnrichNewRegions = true
        batchEnrichOnStartup = false
        enableAutoEnrichment = true
        enableBulkProcessOnLaunch = false
    }
    
    func exportSettings() -> [String: Any] {
        return [
            "locationTrackingDistance": locationTrackingDistance,
            "autoMapCentering": autoMapCentering,
            "preserveZoomPan": preserveZoomPan,
            "explorationRadius": explorationRadius,
            "accuracyThreshold": accuracyThreshold,
            "clusteringRadius": clusteringRadius,
            "mapType": mapType,
            "showUserLocation": showUserLocation,
            "enablePitch": enablePitch,
            "enableRotation": enableRotation,
            "enableGeocoding": enableGeocoding,
            "offlineMode": offlineMode,
            "maxRegionsInMemory": maxRegionsInMemory,
            "backgroundLocationEnabled": backgroundLocationEnabled,
            "percentageDecimals": percentageDecimals,
            "enableExplorationStats": enableExplorationStats,
            "enableReverseGeocoding": enableReverseGeocoding,
            "autoEnrichNewRegions": autoEnrichNewRegions,
            "batchEnrichOnStartup": batchEnrichOnStartup
        ]
    }
    
    func importSettings(from dict: [String: Any]) {
        if let value = dict["locationTrackingDistance"] as? Double {
            locationTrackingDistance = value
        }
        if let value = dict["autoMapCentering"] as? Bool {
            autoMapCentering = value
        }
        if let value = dict["preserveZoomPan"] as? Bool {
            preserveZoomPan = value
        }
        if let value = dict["explorationRadius"] as? Double {
            explorationRadius = value
        }
        if let value = dict["accuracyThreshold"] as? Double {
            accuracyThreshold = value
        }
        if let value = dict["clusteringRadius"] as? Double {
            clusteringRadius = value
        }
        if let value = dict["mapType"] as? Int {
            mapType = value
        }
        if let value = dict["showUserLocation"] as? Bool {
            showUserLocation = value
        }
        if let value = dict["enablePitch"] as? Bool {
            enablePitch = value
        }
        if let value = dict["enableRotation"] as? Bool {
            enableRotation = value
        }
        if let value = dict["enableGeocoding"] as? Bool {
            enableGeocoding = value
        }
        if let value = dict["offlineMode"] as? Bool {
            offlineMode = value
        }
        if let value = dict["maxRegionsInMemory"] as? Int {
            maxRegionsInMemory = value
        }
        if let value = dict["backgroundLocationEnabled"] as? Bool {
            backgroundLocationEnabled = value
        }

        if let value = dict["percentageDecimals"] as? Int {
            percentageDecimals = value
        }
        if let value = dict["enableExplorationStats"] as? Bool {
            enableExplorationStats = value
        }
        
        if let value = dict["enableReverseGeocoding"] as? Bool {
            enableReverseGeocoding = value
        }
        
        if let value = dict["autoEnrichNewRegions"] as? Bool {
            autoEnrichNewRegions = value
        }
        
        if let value = dict["batchEnrichOnStartup"] as? Bool {
            batchEnrichOnStartup = value
        }
    }
}

// MARK: - Settings Extensions
extension AppSettings {
    var currentTrackingOption: TrackingDistanceOption {
        return Self.trackingDistanceOptions.first { $0.value == locationTrackingDistance } 
            ?? Self.trackingDistanceOptions[1] // Default to 50m
    }
    
    var currentRadiusOption: RadiusOption {
        return Self.radiusOptions.first { $0.value == explorationRadius }
            ?? Self.radiusOptions[0] // Default to 100m
    }
    
    var currentAccuracyOption: RadiusOption {
        return Self.accuracyOptions.first { $0.value == accuracyThreshold }
            ?? Self.accuracyOptions[0] // Default to 50m
    }
    
    var currentClusteringOption: RadiusOption {
        return Self.clusteringOptions.first { $0.value == clusteringRadius }
            ?? Self.clusteringOptions[1] // Default to 50m
    }
} 