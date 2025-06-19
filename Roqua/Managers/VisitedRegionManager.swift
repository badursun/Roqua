import Foundation
import CoreLocation
import SwiftUI

@MainActor
class VisitedRegionManager: ObservableObject {
    static let shared = VisitedRegionManager()
    
    @Published var visitedRegions: [VisitedRegion] = []
    @Published var isLoading = false
    
    private let sqliteManager = SQLiteManager.shared
    private let settings = AppSettings.shared
    private let eventBus = EventBus.shared
    
    // Track previous state for change detection
    private var previousCities: Set<String> = []
    private var previousDistricts: Set<String> = []
    private var previousCountries: Set<String> = []
    private var previousReligiousSites: Set<String> = []
    private var previousExplorationPercentage: Double = 0.0
    
    private var lastProcessTime: Date?
    
    private init() {
        loadVisitedRegions()
        initializePreviousState()
        print("🎯 VisitedRegionManager initialized with \(visitedRegions.count) regions")
    }
    
    // MARK: - Data Loading
    func loadVisitedRegions() {
        isLoading = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            let allRegions = self?.sqliteManager.getAllVisitedRegions() ?? []
            
            // Memory'ye sınırlı sayıda region yükle
            let memoryLimit = self?.settings.maxRegionsInMemory ?? 1000
            let regionsToLoad = Array(allRegions.suffix(memoryLimit))
            
            // Mevcut region'ları GridHashManager'a yükle
            for region in regionsToLoad {
                Task { @MainActor in
                    GridHashManager.shared.register(region: region)
                }
            }
            
            DispatchQueue.main.async {
                self?.visitedRegions = regionsToLoad
                self?.isLoading = false
                
                // Previous discoveries için cache oluştur
                let cities = Set(allRegions.compactMap { $0.city })
                let districts = Set(allRegions.compactMap { $0.district })
                let countries = Set(allRegions.compactMap { $0.country })
                let religiousSites = Set(allRegions.filter { region in
                    guard let poiCategory = region.poiCategory else { return false }
                    let religiousCategories = ["mosque", "church", "synagogue", "temple"]
                    return religiousCategories.contains(poiCategory.lowercased())
                }.compactMap { $0.poiName })
                
                self?.previousCities = cities
                self?.previousDistricts = districts  
                self?.previousCountries = countries
                self?.previousReligiousSites = religiousSites
                
                let explorationPercent = GridHashManager.shared.getExplorationPercentage(decimals: 6)
                print("🗄️ Loaded \(regionsToLoad.count) visited regions from database (total: \(allRegions.count))")
                print("🌍 Current exploration: \(explorationPercent)%")
                print("🎯 Discovery cache: \(cities.count) cities, \(districts.count) districts, \(countries.count) countries, \(religiousSites.count) religious sites")
                
                if allRegions.count > memoryLimit {
                    print("📊 Memory optimization: Showing \(regionsToLoad.count)/\(allRegions.count) regions (limit: \(memoryLimit))")
                }
            }
        }
    }
    
    // MARK: - Smart Location Processing
    func processNewLocation(_ location: CLLocation) {
        print("🚀 VISITED REGION MANAGER: processNewLocation called!")
        print("🚀 VISITED REGION MANAGER: Location: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude))")
        
        // Timestamp kontrolü - çok sık işlem yapılmasını önle
        let now = Date()
        if let lastProcessTime = lastProcessTime, now.timeIntervalSince(lastProcessTime) < 5.0 {
            // 5 saniyeden az süre geçmişse işleme
            print("⏱️ Location processing throttled - last process: \(String(format: "%.1f", now.timeIntervalSince(lastProcessTime)))s ago")
            return
        }
        
        print("🎯 Processing location: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude)) ±\(Int(location.horizontalAccuracy))m")
        
        // Background thread'de işle
        Task.detached { [weak self] in
            await self?.processLocationInBackground(location)
        }
    }
    
    private func processLocationInBackground(_ location: CLLocation) async {
        let accuracy = location.horizontalAccuracy
        print("📍 PROCESSING LOCATION: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude)) - accuracy: \(Int(accuracy))m")
        
        // LocationManager zaten accuracy kontrolünü yaptı, buraya gelen location'lar geçerli
        // Accuracy kontrolü artık LocationManager'da tek yerden yapılıyor
        print("✅ Location accepted - passed LocationManager accuracy check (accuracy: \(Int(accuracy))m)")
        
        // Yakındaki bölgeleri kontrol et
        let nearbyRegions = await findNearbyRegions(location: location)
        print("🔍 Found \(nearbyRegions.count) nearby regions")
        
        if let existingRegion = await findClusterableRegion(location: location, nearbyRegions: nearbyRegions) {
            // Mevcut bölgeyi güncelle - ama çok sık güncelleme yapma
            if await shouldUpdateExistingRegion(existingRegion, with: location) {
                print("🔄 Updating existing region (ID: \(existingRegion.id ?? -1))")
                await updateExistingRegion(existingRegion, with: location)
            } else {
                print("⏭️ Skipping update - too recent (region ID: \(existingRegion.id ?? -1))")
            }
        } else if await shouldCreateNewRegion(location: location, nearbyRegions: nearbyRegions) {
            // Yeni bölge oluştur
            print("✨ Creating new region")
            await createNewRegion(from: location)
        } else {
            print("⏭️ Skipping - too close to existing regions")
        }
        
        // Process time'ı güncelle
        await MainActor.run { [weak self] in
            self?.lastProcessTime = Date()
        }
    }
    
    private func findNearbyRegions(location: CLLocation) async -> [VisitedRegion] {
        let clusteringRadius = await settings.clusteringRadius
        let searchRadius = clusteringRadius * 2 // Biraz daha geniş arama
        return await MainActor.run {
            visitedRegions.filter { region in
                region.distance(to: location) <= searchRadius
            }
        }
    }
    
    private func findClusterableRegion(location: CLLocation, nearbyRegions: [VisitedRegion]) async -> VisitedRegion? {
        let clusteringRadius = await settings.clusteringRadius
        // En yakın bölgeyi bul ve clustering radius içinde mi kontrol et
        return nearbyRegions
            .filter { $0.distance(to: location) <= clusteringRadius }
            .min { region1, region2 in
                region1.distance(to: location) < region2.distance(to: location)
            }
    }
    
    private func shouldCreateNewRegion(location: CLLocation, nearbyRegions: [VisitedRegion]) async -> Bool {
        let locationTrackingDistance = await settings.locationTrackingDistance
        // Settings'den minimum distance al (location tracking distance'ın yarısı)
        let minimumDistance = locationTrackingDistance / 2
        return nearbyRegions.allSatisfy { region in
            region.distance(to: location) >= minimumDistance
        }
    }
    
    private func shouldUpdateExistingRegion(_ region: VisitedRegion, with location: CLLocation) async -> Bool {
        // Son güncelleme zamanını kontrol et - çok sık güncelleme yapma
        if let lastUpdate = region.timestampEnd {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            if timeSinceLastUpdate < 30.0 { // 30 saniye minimum
                return false
            }
        }
        return true
    }
    
    private func updateExistingRegion(_ region: VisitedRegion, with location: CLLocation) async {
        var updatedRegion = region
        updatedRegion.visitCount += 1
        updatedRegion.timestampEnd = Date()
        
        // Database'i güncelle
        if let regionId = region.id {
            _ = sqliteManager.updateVisitedRegion(updatedRegion)
        }
        
        // Memory'de güncelle
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            if let index = self.visitedRegions.firstIndex(where: { $0.id == region.id }) {
                self.visitedRegions[index] = updatedRegion
            }
        }
        
        // POI enrichment - Her zaman çalıştır (ziyaret sayısı için)
        print("🕌 Starting POI enrichment for existing region (checking for POI visits)...")
        POIEnrichmentManager.shared.enrichWithPOI(coordinate: location.coordinate) { [weak self] poiInfo in
            Task { @MainActor in
                await self?.handlePOIEnrichment(poiInfo: poiInfo, for: updatedRegion)
            }
        }
        
        // Sadece önemli güncellemelerde log
        if updatedRegion.visitCount % 5 == 0 { // Her 5 ziyarette bir log
            print("🎯 Updated existing region: \(region.locationDescription) (visit #\(updatedRegion.visitCount))")
        }
    }
    
    private func createNewRegion(from location: CLLocation) async {
        let radius = Int(await settings.explorationRadius) // PRD'ye göre 150m
        
        let newRegion = VisitedRegion(
            id: nil,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: radius, // Settings'den al
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
        
        print("💾 Saving new region to database...")
        
        // Database'e kaydet
        if let regionId = sqliteManager.insertVisitedRegion(newRegion) {
            var savedRegion = newRegion
            savedRegion.id = regionId
            
            print("✅ Region saved with ID: \(regionId)")
            
            // Memory'e ekle - maxRegionsInMemory limit kontrolü ile
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.visitedRegions.append(savedRegion)
                
                // Memory limit kontrolü - settings'den al
                let memoryLimit = self.settings.maxRegionsInMemory
                if self.visitedRegions.count > memoryLimit {
                    // En eski region'ları çıkar, en yenileri tut
                    self.visitedRegions = Array(self.visitedRegions.suffix(memoryLimit))
                    print("📊 Memory limit reached - trimmed to \(memoryLimit) regions")
                }
                
                print("📊 Total regions in memory: \(self.visitedRegions.count)/\(memoryLimit)")
                
                // Event publish et
                self.eventBus.publish(achievementEvent: .newRegionDiscovered(savedRegion))
                
                // Exploration percentage'ı güncelle
                self.updateExplorationPercentage()
            }
            
            // Reverse geocoding başlat (background'da)
            let autoEnrich = await settings.autoEnrichNewRegions
            print("🔧 autoEnrichNewRegions setting: \(autoEnrich)")
            
            if autoEnrich {
                print("🌍 Starting reverse geocoding...")
                await ReverseGeocoder.shared.enrichRegion(savedRegion) { [weak self] enrichedRegion in
                    Task { @MainActor in
                        await self?.handleEnrichedRegion(enrichedRegion, oldRegion: savedRegion)
                    }
                }
            }
            
            // POI enrichment - DEBUG: Always run for testing
            print("🕌 Starting POI enrichment (DEBUG: always enabled)...")
            POIEnrichmentManager.shared.enrichWithPOI(coordinate: location.coordinate) { [weak self] poiInfo in
                Task { @MainActor in
                    await self?.handlePOIEnrichment(poiInfo: poiInfo, for: savedRegion)
                }
            }
            
            print("🎯 New region created: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude)) (radius: \(radius)m)")
        } else {
            print("❌ Failed to save region to database")
        }
    }
    
    private func handleEnrichedRegion(_ enrichedRegion: VisitedRegion, oldRegion: VisitedRegion) async {
        print("🌍 Reverse geocoding completed for region ID: \(enrichedRegion.id ?? -1)")
        
        // Database'i güncelle
        if sqliteManager.updateVisitedRegion(enrichedRegion) {
            print("💾 Region enrichment saved to database")
            
            // Memory'de güncelle
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if let index = self.visitedRegions.firstIndex(where: { $0.id == enrichedRegion.id }) {
                    self.visitedRegions[index] = enrichedRegion
                }
                
                // Event publish et
                self.eventBus.publish(achievementEvent: .regionEnriched(enrichedRegion, oldRegion: oldRegion))
                
                // Geographic discovery events
                self.checkGeographicDiscoveries(enrichedRegion)
            }
            
            print("🌍 Region enriched: \(enrichedRegion.locationDescription)")
        } else {
            print("❌ Failed to save enriched region to database")
        }
    }
    
    private func handlePOIEnrichment(poiInfo: POIInfo?, for region: VisitedRegion) async {
        guard let poiInfo = poiInfo else {
            print("📍 No POI found for region ID: \(region.id ?? -1)")
            return
        }
        
        print("🕌 POI enrichment completed for region ID: \(region.id ?? -1)")
        print("🏷️ POI Details: '\(poiInfo.name)' - Category: \(poiInfo.categoryString) - Type: \(poiInfo.typeString)")
        
        // Update region with POI information
        var enrichedRegion = region
        enrichedRegion.poiName = poiInfo.name
        enrichedRegion.poiCategory = poiInfo.categoryString  
        enrichedRegion.poiType = poiInfo.typeString
        
        // Database'i güncelle
        if sqliteManager.updateVisitedRegion(enrichedRegion) {
            print("💾 POI enrichment saved to database")
            
            // Memory'de güncelle
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if let index = self.visitedRegions.firstIndex(where: { $0.id == enrichedRegion.id }) {
                    self.visitedRegions[index] = enrichedRegion
                }
                
                // POI discovery events
                self.checkPOIDiscoveries(enrichedRegion)
            }
            
            print("🕌 POI enriched: \(poiInfo.name) (\(poiInfo.categoryString))")
        } else {
            print("❌ Failed to save POI enriched region to database")
        }
    }
    
    @MainActor
    private func checkGeographicDiscoveries(_ region: VisitedRegion) {
        var discoveries: [String] = []
        
        // City discovery
        if let city = region.city, !previousCities.contains(city) {
            previousCities.insert(city)
            eventBus.publish(achievementEvent: .newCityDiscovered(city, region: region))
            discoveries.append("city: \(city)")
        }
        
        // District discovery
        if let district = region.district, !previousDistricts.contains(district) {
            previousDistricts.insert(district)
            eventBus.publish(achievementEvent: .newDistrictDiscovered(district, region: region))
            discoveries.append("district: \(district)")
        }
        
        // Country discovery
        if let country = region.country, !previousCountries.contains(country) {
            previousCountries.insert(country)
            eventBus.publish(achievementEvent: .newCountryDiscovered(country, region: region))
            discoveries.append("country: \(country)")
        }
        
        if !discoveries.isEmpty {
            print("🎉 New geographic discoveries: \(discoveries.joined(separator: ", "))")
        }
    }
    
    @MainActor
    private func checkPOIDiscoveries(_ region: VisitedRegion) {
        guard let poiName = region.poiName, let poiCategory = region.poiCategory else { return }
        
        var discoveries: [String] = []
        
        // Apple POI Categories - Religious sites
        let religiousCategories = ["ReligiousSite", "mosque", "church", "synagogue", "temple", "religious_site"]
        
        // Religious site discovery
        if religiousCategories.contains(poiCategory) || religiousCategories.contains(poiCategory.lowercased()) {
            if !previousReligiousSites.contains(poiName) {
                previousReligiousSites.insert(poiName)
                eventBus.publish(achievementEvent: .newReligiousSiteDiscovered(poiName, category: poiCategory, region: region))
                discoveries.append("religious site: \(poiName) (\(poiCategory))")
            }
        }
        
        // Other POI categories for future achievements
        let healthcareCategories = ["Hospital", "Pharmacy"]
        let educationCategories = ["School", "University", "Library"]
        
        // Healthcare discovery
        if healthcareCategories.contains(poiCategory) {
            eventBus.publish(achievementEvent: .newPOIDiscovered(poiName, category: poiCategory, region: region))
            discoveries.append("healthcare: \(poiName) (\(poiCategory))")
        }
        
        // Education discovery
        if educationCategories.contains(poiCategory) {
            eventBus.publish(achievementEvent: .newPOIDiscovered(poiName, category: poiCategory, region: region))
            discoveries.append("education: \(poiName) (\(poiCategory))")
        }
        
        if !discoveries.isEmpty {
            print("🎯 POI discoveries: \(discoveries.joined(separator: ", "))")
        }
    }
    
    @MainActor
    private func updateExplorationPercentage() {
        let newPercentage = GridHashManager.shared.getExplorationPercentageDouble()
        if abs(newPercentage - previousExplorationPercentage) > 0.00001 { // Meaningful change
            let oldPercentage = previousExplorationPercentage
            previousExplorationPercentage = newPercentage
            eventBus.publish(achievementEvent: .explorationPercentageChanged(newPercentage, previousPercentage: oldPercentage))
            
            // Sadece önemli değişikliklerde log
            if abs(newPercentage - oldPercentage) > 0.001 {
                print("📈 Exploration updated: \(String(format: "%.6f", oldPercentage))% → \(String(format: "%.6f", newPercentage))%")
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
    func migrateFromExploredCircles(_ circles: [CLLocationCoordinate2D]) {
        print("🔄 Starting migration from \(circles.count) explored circles...")
        
        Task.detached { [weak self] in
            for (index, coordinate) in circles.enumerated() {
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                await self?.processNewLocation(location)
                
                // Throttle migration to avoid overwhelming the system
                if index % 10 == 0 {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
            }
            
            await MainActor.run {
                print("🎉 Migration completed!")
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
    
    // MARK: - Event Helper Methods
    
    @MainActor
    private func initializePreviousState() {
        previousCities = Set(visitedRegions.compactMap { $0.city })
        previousDistricts = Set(visitedRegions.compactMap { $0.district })
        previousCountries = Set(visitedRegions.compactMap { $0.country })
        previousExplorationPercentage = GridHashManager.shared.getExplorationPercentageDouble()
    }
} 