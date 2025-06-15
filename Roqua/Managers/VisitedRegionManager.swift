import Foundation
import CoreLocation

class VisitedRegionManager: ObservableObject {
    static let shared = VisitedRegionManager()
    
    @Published var visitedRegions: [VisitedRegion] = []
    @Published var isLoading = false
    
    private let sqliteManager = SQLiteManager.shared
    private let settings = AppSettings.shared
    
    private init() {
        loadVisitedRegions()
        print("🎯 VisitedRegionManager initialized with \(visitedRegions.count) regions")
    }
    
    // MARK: - Data Loading
    func loadVisitedRegions() {
        isLoading = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            let regions = self?.sqliteManager.getAllVisitedRegions() ?? []
            
            // Mevcut region'ları GridHashManager'a yükle
            for region in regions {
                Task { @MainActor in
                    GridHashManager.shared.register(region: region)
                }
            }
            
            DispatchQueue.main.async {
                self?.visitedRegions = regions
                self?.isLoading = false
                let explorationPercent = GridHashManager.shared.getExplorationPercentage(decimals: 6)
                print("🗄️ Loaded \(regions.count) visited regions from database")
                print("🌍 Current exploration: \(explorationPercent)%")
            }
        }
    }
    
    // MARK: - Smart Location Processing
    func processNewLocation(_ location: CLLocation) {
        // Background thread'de işle
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.processLocationInBackground(location)
        }
    }
    
    private func processLocationInBackground(_ location: CLLocation) {
        let accuracy = location.horizontalAccuracy
        
        // Settings'den accuracy threshold al - main thread'de al
        let accuracyThreshold = DispatchQueue.main.sync { settings.accuracyThreshold }
        
        guard accuracy <= accuracyThreshold && accuracy > 0 else {
            print("🎯 Location rejected due to poor accuracy: \(accuracy)m (threshold: \(accuracyThreshold)m)")
            return
        }
        
        // Yakındaki bölgeleri kontrol et
        let nearbyRegions = findNearbyRegions(location: location)
        
        if let existingRegion = findClusterableRegion(location: location, nearbyRegions: nearbyRegions) {
            // Mevcut bölgeyi genişlet
            updateExistingRegion(existingRegion, with: location)
        } else if shouldCreateNewRegion(location: location, nearbyRegions: nearbyRegions) {
            // Yeni bölge oluştur
            createNewRegion(from: location)
        }
        // Else: Çok yakın, hiçbir şey yapma
    }
    
    private func findNearbyRegions(location: CLLocation) -> [VisitedRegion] {
        let clusteringRadius = DispatchQueue.main.sync { settings.clusteringRadius }
        let searchRadius = clusteringRadius * 2 // Biraz daha geniş arama
        return visitedRegions.filter { region in
            region.distance(to: location) <= searchRadius
        }
    }
    
    private func findClusterableRegion(location: CLLocation, nearbyRegions: [VisitedRegion]) -> VisitedRegion? {
        let clusteringRadius = DispatchQueue.main.sync { settings.clusteringRadius }
        // En yakın bölgeyi bul ve clustering radius içinde mi kontrol et
        return nearbyRegions
            .filter { $0.distance(to: location) <= clusteringRadius }
            .min { region1, region2 in
                region1.distance(to: location) < region2.distance(to: location)
            }
    }
    
    private func shouldCreateNewRegion(location: CLLocation, nearbyRegions: [VisitedRegion]) -> Bool {
        let locationTrackingDistance = DispatchQueue.main.sync { settings.locationTrackingDistance }
        // Settings'den minimum distance al (location tracking distance'ın yarısı)
        let minimumDistance = locationTrackingDistance / 2
        return nearbyRegions.allSatisfy { region in
            region.distance(to: location) >= minimumDistance
        }
    }
    
    private func updateExistingRegion(_ region: VisitedRegion, with location: CLLocation) {
        var updatedRegion = region
        
        // Visit count artır
        updatedRegion.visitCount += 1
        updatedRegion.timestampEnd = Date()
        
        // Accuracy güncelle (daha iyi accuracy varsa)
        if let currentAccuracy = updatedRegion.accuracy,
           location.horizontalAccuracy < currentAccuracy {
            updatedRegion.accuracy = location.horizontalAccuracy
        } else if updatedRegion.accuracy == nil {
            updatedRegion.accuracy = location.horizontalAccuracy
        }
        
        // Gerekirse radius'u genişlet
        let distance = region.distance(to: location)
        if distance > Double(region.radius) {
            updatedRegion.radius = max(region.radius, Int(distance) + 20) // 20m buffer
        }
        
        // Database'i güncelle
        if sqliteManager.updateVisitedRegion(updatedRegion) {
            // GridHashManager'ı güncelle (radius değişmişse yeni grid'ler eklenebilir)
            Task { @MainActor in
                GridHashManager.shared.register(region: updatedRegion)
            }
            
            DispatchQueue.main.async { [weak self] in
                if let index = self?.visitedRegions.firstIndex(where: { $0.id == region.id }) {
                    self?.visitedRegions[index] = updatedRegion
                    print("🎯 Updated existing region: \(updatedRegion.locationDescription)")
                }
            }
        }
    }
    
    private func createNewRegion(from location: CLLocation) {
        // Settings'den exploration radius al - main thread'de al
        let explorationRadius = DispatchQueue.main.sync { settings.explorationRadius }
        let radius = Int(explorationRadius)
        
        let newRegion = VisitedRegion(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: radius,
            timestampStart: Date(),
            accuracy: location.horizontalAccuracy
        )
        
        // Database'e ekle
        if let insertedId = sqliteManager.insertVisitedRegion(newRegion) {
            var regionWithId = newRegion
            regionWithId.id = insertedId
            
            // GridHashManager'a kayıt et
            Task { @MainActor in
                GridHashManager.shared.register(region: regionWithId)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.visitedRegions.append(regionWithId)
                let explorationPercent = GridHashManager.shared.getExplorationPercentage(decimals: 6)
                print("🎯 Created new region: \(regionWithId.centerCoordinate) with radius \(radius)m")
                print("🌍 Exploration: \(explorationPercent)%")
                print("📊 Total regions: \(self?.visitedRegions.count ?? 0)")
            }
        }
    }
    
    // MARK: - Fog of War Compatibility
    /// ExploredCirclesManager ile uyumluluk için - mevcut fog of war sistemine koordinat listesi sağlar
    func getCoordinatesForFogOfWar() -> [CLLocationCoordinate2D] {
        return visitedRegions.map { $0.centerCoordinate }
    }
    
    // MARK: - Migration Support
    /// ExploredCirclesManager'dan geçiş için
    func migrateFromExploredCircles(_ coordinates: [CLLocationCoordinate2D]) {
        print("🔄 Starting migration from ExploredCircles...")
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            var migratedCount = 0
            
            for coordinate in coordinates {
                let region = VisitedRegion(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radius: 200,
                    timestampStart: Date().addingTimeInterval(-Double.random(in: 0...86400)) // Random time in last day
                )
                
                if let insertedId = self?.sqliteManager.insertVisitedRegion(region) {
                    var regionWithId = region
                    regionWithId.id = insertedId
                    
                    // GridHashManager'a kayıt et
                    GridHashManager.shared.register(region: regionWithId)
                    migratedCount += 1
                }
            }
            
            DispatchQueue.main.async {
                self?.loadVisitedRegions() // Reload from database
                let explorationPercent = GridHashManager.shared.getExplorationPercentage(decimals: 6)
                print("🔄 Migration completed: \(migratedCount)/\(coordinates.count) regions migrated")
                print("🌍 Total exploration: \(explorationPercent)%")
            }
        }
    }
    
    // MARK: - Statistics
    func getTotalExploredArea() -> Double {
        return visitedRegions.reduce(0) { total, region in
            total + region.areaSquareMeters
        }
    }
    
    func getRegionsByCountry() -> [String: Int] {
        var countryStats: [String: Int] = [:]
        
        for region in visitedRegions {
            let country = region.country ?? "Bilinmeyen"
            countryStats[country, default: 0] += 1
        }
        
        return countryStats
    }
    
    func getRegionsByCity() -> [String: Int] {
        var cityStats: [String: Int] = [:]
        
        for region in visitedRegions {
            let city = region.city ?? "Bilinmeyen"
            cityStats[city, default: 0] += 1
        }
        
        return cityStats
    }
    
    // MARK: - Data Management
    func clearAllData() {
        isLoading = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            let success = self?.sqliteManager.deleteAllVisitedRegions() ?? false
            
            DispatchQueue.main.async {
                if success {
                    self?.visitedRegions.removeAll()
                    // GridHashManager'ı da temizle
                    GridHashManager.shared.clearAll()
                    print("🗄️ All visited regions and grid hashes cleared")
                } else {
                    print("❌ Failed to clear visited regions")
                }
                self?.isLoading = false
            }
        }
    }
    
    // MARK: - Debug & Statistics
    @MainActor
    func printStatistics() {
        print("📊 VisitedRegionManager Statistics:")
        print("   Total regions: \(visitedRegions.count)")
        print("   Memory usage: \(visitedRegions.count * MemoryLayout<VisitedRegion>.size) bytes")
        
        // Accuracy distribution
        let accuracies = visitedRegions.compactMap { $0.accuracy }
        if !accuracies.isEmpty {
            let avgAccuracy = accuracies.reduce(0, +) / Double(accuracies.count)
            print("   Average accuracy: \(String(format: "%.1f", avgAccuracy))m")
        }
        
        // GridHashManager istatistikleri
        let explorationPercent = GridHashManager.shared.getExplorationPercentage(decimals: 9)
        let gridCount = GridHashManager.shared.exportHashes().count
        print("🌍 GridHash Statistics:")
        print("   Exploration: \(explorationPercent)%")
        print("   Grid count: \(gridCount)")
        print("   Grid efficiency: \(String(format: "%.2f", Double(gridCount) / Double(visitedRegions.count))) grids/region")
    }
} 