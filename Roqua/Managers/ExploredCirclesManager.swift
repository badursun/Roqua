import Foundation
import CoreLocation

// MARK: - Explored Circles Manager
@MainActor
class ExploredCirclesManager: ObservableObject {
    static let shared = ExploredCirclesManager()
    
    @Published var exploredCircles: [CLLocationCoordinate2D] = []
    private let settings = AppSettings.shared
    private let storageKey = "exploredCircles"
    
    private init() {
        loadFromStorage()
        print("🎯 ExploredCirclesManager initialized with \(exploredCircles.count) saved circles")
    }
    
    func addLocation(_ location: CLLocation) {
        let newCoordinate = location.coordinate
        
        // Settings'den exploration radius al - bu alanlar overlap olmamalı
        let minimumDistance = settings.explorationRadius * 0.5 // Radius'un yarısı kadar mesafe
        
        // Çok yakın bir konum varsa ekleme (overlap kontrolü)
        for existingCoordinate in exploredCircles {
            let existingLocation = CLLocation(latitude: existingCoordinate.latitude, longitude: existingCoordinate.longitude)
            if location.distance(from: existingLocation) < minimumDistance {
                print("🔄 Location too close to existing circle, skipping: \(String(format: "%.6f", newCoordinate.latitude)), \(String(format: "%.6f", newCoordinate.longitude))")
                return
            }
        }
        
        // Yeni konumu ekle
        exploredCircles.append(newCoordinate)
        saveToStorage()
        
        // GridHashManager'ı güncelle - anlık yüzdelik hesaplama için
        updateGridHashManager(for: location)
        
        print("🎯 New explored area added: \(String(format: "%.6f", newCoordinate.latitude)), \(String(format: "%.6f", newCoordinate.longitude))")
        print("📊 Total explored areas: \(exploredCircles.count), radius: \(Int(settings.explorationRadius))m")
    }
    
    // MARK: - GridHashManager Bridge
    private func updateGridHashManager(for location: CLLocation) {
        let oldPercentage = GridHashManager.shared.formattedPercentage
        print("🔄 ExploredCirclesManager: Updating GridHashManager")
        print("   📊 Old percentage: \(oldPercentage)%")
        
        // Temporary VisitedRegion oluştur GridHashManager için
        let tempRegion = VisitedRegion(
            id: nil,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: Int(settings.explorationRadius),
            timestampStart: Date(),
            timestampEnd: nil,
            visitCount: 1,
            city: nil,
            district: nil,
            country: nil,
            countryCode: nil,
            geohash: nil,
            accuracy: location.horizontalAccuracy
        )
        
        // GridHashManager'ı güncelle
        GridHashManager.shared.register(region: tempRegion)
        
        let newPercentage = GridHashManager.shared.formattedPercentage
        print("   📈 New percentage: \(newPercentage)%")
        print("   🎯 ExploredCircles count: \(exploredCircles.count)")
        print("   🌍 GridHash count: \(GridHashManager.shared.exportHashes().count)")
        
        if oldPercentage != newPercentage {
            print("✅ Percentage CHANGED: \(oldPercentage)% → \(newPercentage)%")
        } else {
            print("⚠️ Percentage NOT CHANGED: \(oldPercentage)%")
        }
    }
    
    // MARK: - Persistent Storage
    private func saveToStorage() {
        let coordinateData = exploredCircles.map { coordinate in
            ["latitude": coordinate.latitude, "longitude": coordinate.longitude]
        }
        UserDefaults.standard.set(coordinateData, forKey: storageKey)
        print("💾 Saved \(exploredCircles.count) explored circles to storage")
    }
    
    private func loadFromStorage() {
        guard let coordinateData = UserDefaults.standard.array(forKey: storageKey) as? [[String: Double]] else {
            print("📂 No saved explored circles found")
            return
        }
        
        exploredCircles = coordinateData.compactMap { data in
            guard let latitude = data["latitude"], let longitude = data["longitude"] else { return nil }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        // Mevcut circles'ı GridHashManager'a yükle
        loadExistingCirclesToGridHash()
        
        print("📂 Loaded \(exploredCircles.count) explored circles from storage")
    }
    
    // MARK: - GridHash Migration
    private func loadExistingCirclesToGridHash() {
        print("🔄 Loading existing circles to GridHashManager...")
        
        for coordinate in exploredCircles {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let tempRegion = VisitedRegion(
                id: nil,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radius: Int(settings.explorationRadius),
                timestampStart: Date(),
                timestampEnd: nil,
                visitCount: 1,
                city: nil,
                district: nil,
                country: nil,
                countryCode: nil,
                geohash: nil,
                accuracy: 10.0
            )
            
            GridHashManager.shared.register(region: tempRegion)
        }
        
        print("✅ GridHashManager synced with \(exploredCircles.count) existing circles")
        print("🌍 Current exploration percentage: \(GridHashManager.shared.formattedPercentage)%")
    }
    
    // MARK: - Clear Data
    func clearAllData() {
        exploredCircles.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        // GridHashManager'ı da temizle
        GridHashManager.shared.clearAll()
        print("🗑️ All explored circles and grid hashes cleared")
    }
} 