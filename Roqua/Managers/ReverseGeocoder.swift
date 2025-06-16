import Foundation
import CoreLocation
import Combine

// MARK: - Location Info Model
struct LocationInfo {
    let coordinate: CLLocationCoordinate2D
    let country: String?
    let city: String?
    let district: String?
    let timestamp: Date
    
    var displayText: String {
        var components: [String] = []
        
        if let district = district {
            components.append(district)
        }
        if let city = city {
            components.append(city)
        }
        if let country = country {
            components.append(country)
        }
        
        return components.isEmpty ? "Bilinmeyen Konum" : components.joined(separator: ", ")
    }
    
    var shortDisplayText: String {
        if let district = district, let city = city {
            return "\(district), \(city)"
        } else if let city = city {
            return city
        } else if let country = country {
            return country
        }
        return "Bilinmeyen"
    }
}

// MARK: - Reverse Geocoder Manager
@MainActor
class ReverseGeocoder: ObservableObject {
    static let shared = ReverseGeocoder()
    
    @Published var currentLocationInfo: LocationInfo?
    @Published var isGeocoding: Bool = false
    
    private let geocoder = CLGeocoder()
    private var cache: [String: LocationInfo] = [:]
    private var lastGeocodedLocation: CLLocationCoordinate2D?
    private let minimumDistanceForNewGeocode: Double = 500.0 // 500m
    
    // MARK: - VisitedRegion Enrichment
    private let enrichmentQueue = DispatchQueue(label: "reverse-geocoding-enrichment", qos: .utility)
    private var enrichmentCache: [String: GeographicInfo] = [:]
    
    private init() {
        loadCacheFromUserDefaults()
        loadEnrichmentCache()
    }
    
    // MARK: - Public Methods
    
    func geocodeLocation(_ location: CLLocation) {
        // Çok yakın konumlar için cache kullan
        if let lastLocation = lastGeocodedLocation {
            let distance = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
                .distance(from: location)
            
            if distance < minimumDistanceForNewGeocode {
                return // Çok yakın, geocoding yapma
            }
        }
        
        let cacheKey = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        
        // Cache kontrolü
        if let cachedInfo = cache[cacheKey] {
            currentLocationInfo = cachedInfo
            return
        }
        
        // Yeni geocoding isteği
        performGeocoding(for: location)
    }
    
    // MARK: - VisitedRegion Enrichment
    
    /// VisitedRegion'ı coğrafi bilgilerle zenginleştir
    func enrichRegion(_ region: VisitedRegion, completion: @escaping (VisitedRegion) -> Void) {
        let location = CLLocation(latitude: region.latitude, longitude: region.longitude)
        let cacheKey = "\(region.latitude),\(region.longitude)"
        
        // Enrichment cache kontrolü
        if let cachedInfo = enrichmentCache[cacheKey] {
            var enrichedRegion = region
            enrichedRegion.city = cachedInfo.city
            enrichedRegion.district = cachedInfo.district
            enrichedRegion.country = cachedInfo.country
            enrichedRegion.countryCode = cachedInfo.countryCode
            
            completion(enrichedRegion)
            return
        }
        
        // Background'da reverse geocoding yap
        enrichmentQueue.async { [weak self] in
            self?.performEnrichmentGeocoding(for: region, location: location, completion: completion)
        }
    }
    
    /// Birden fazla region'ı batch olarak zenginleştir
    func batchEnrichRegions(_ regions: [VisitedRegion], completion: @escaping ([VisitedRegion]) -> Void) {
        let group = DispatchGroup()
        var enrichedRegions: [VisitedRegion] = []
        let lock = NSLock()
        
        for region in regions {
            group.enter()
            enrichRegion(region) { enriched in
                lock.lock()
                enrichedRegions.append(enriched)
                lock.unlock()
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(enrichedRegions)
        }
    }
    
    /// Zenginleştirilmemiş region'ları bul ve işle
    func enrichUnenrichedRegions() {
        let sqliteManager = SQLiteManager.shared
        
        enrichmentQueue.async {
            let unenrichedRegions = sqliteManager.getAllVisitedRegions().filter { region in
                region.city == nil || region.country == nil
            }
            
            print("🌍 Found \(unenrichedRegions.count) unenriched regions")
            
            if !unenrichedRegions.isEmpty {
                self.batchEnrichRegions(unenrichedRegions) { enrichedRegions in
                    // Database'i güncelle
                    for region in enrichedRegions {
                        if region.isEnriched {
                            sqliteManager.updateVisitedRegion(region)
                        }
                    }
                    print("🌍 Batch enrichment completed for \(enrichedRegions.count) regions")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performGeocoding(for location: CLLocation) {
        guard !isGeocoding else { return }
        
        isGeocoding = true
        lastGeocodedLocation = location.coordinate
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isGeocoding = false
                
                if let error = error {
                    print("🌍 Geocoding error: \(error.localizedDescription)")
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    print("🌍 No placemark found")
                    return
                }
                
                let locationInfo = LocationInfo(
                    coordinate: location.coordinate,
                    country: placemark.country,
                    city: placemark.locality ?? placemark.administrativeArea,
                    district: placemark.subLocality ?? placemark.subAdministrativeArea,
                    timestamp: Date()
                )
                
                self?.currentLocationInfo = locationInfo
                self?.cacheLocationInfo(locationInfo, for: location.coordinate)
                
                print("🌍 Geocoded: \(locationInfo.displayText)")
            }
        }
    }
    
    // MARK: - Private Methods (VisitedRegion Enrichment için YENİ)
    
    private func performEnrichmentGeocoding(for region: VisitedRegion, location: CLLocation, completion: @escaping (VisitedRegion) -> Void) {
        let geocoder = CLGeocoder() // Ayrı geocoder instance
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            var enrichedRegion = region
            
            if let placemark = placemarks?.first, error == nil {
                let info = GeographicInfo(
                    city: placemark.locality ?? placemark.administrativeArea,
                    district: placemark.subLocality ?? placemark.subAdministrativeArea,
                    country: placemark.country,
                    countryCode: placemark.isoCountryCode
                )
                
                // Enrichment cache'e kaydet
                let cacheKey = "\(region.latitude),\(region.longitude)"
                self?.enrichmentCache[cacheKey] = info
                self?.saveEnrichmentCache()
                
                // Region'ı zenginleştir
                enrichedRegion.city = info.city
                enrichedRegion.district = info.district
                enrichedRegion.country = info.country
                enrichedRegion.countryCode = info.countryCode
                
                print("🌍 Enriched region: \(info.city ?? "Unknown"), \(info.country ?? "Unknown")")
            } else {
                print("⚠️ Enrichment geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
            }
            
            DispatchQueue.main.async {
                completion(enrichedRegion)
            }
        }
    }
    
    private func cacheLocationInfo(_ info: LocationInfo, for coordinate: CLLocationCoordinate2D) {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude)"
        cache[cacheKey] = info
        saveCacheToUserDefaults()
    }
    
    // MARK: - Cache Management
    
    private func loadCacheFromUserDefaults() {
        // Basit cache implementasyonu - ileride Core Data'ya geçilebilir
        if let data = UserDefaults.standard.data(forKey: "ReverseGeocoderCache"),
           let decoded = try? JSONDecoder().decode([String: CachedLocationInfo].self, from: data) {
            
            cache = decoded.compactMapValues { cached in
                LocationInfo(
                    coordinate: CLLocationCoordinate2D(latitude: cached.latitude, longitude: cached.longitude),
                    country: cached.country,
                    city: cached.city,
                    district: cached.district,
                    timestamp: cached.timestamp
                )
            }
            
            print("🌍 Loaded \(cache.count) cached locations")
        }
    }
    
    private func saveCacheToUserDefaults() {
        let cachedData = cache.compactMapValues { info in
            CachedLocationInfo(
                latitude: info.coordinate.latitude,
                longitude: info.coordinate.longitude,
                country: info.country,
                city: info.city,
                district: info.district,
                timestamp: info.timestamp
            )
        }
        
        if let encoded = try? JSONEncoder().encode(cachedData) {
            UserDefaults.standard.set(encoded, forKey: "ReverseGeocoderCache")
        }
    }
    
    // MARK: - Enrichment Cache Management (YENİ)
    
    private func loadEnrichmentCache() {
        if let data = UserDefaults.standard.data(forKey: "ReverseGeocoderEnrichmentCache"),
           let decoded = try? JSONDecoder().decode([String: GeographicInfo].self, from: data) {
            enrichmentCache = decoded
            print("🌍 Loaded \(enrichmentCache.count) enrichment cache entries")
        }
    }
    
    private func saveEnrichmentCache() {
        if let encoded = try? JSONEncoder().encode(enrichmentCache) {
            UserDefaults.standard.set(encoded, forKey: "ReverseGeocoderEnrichmentCache")
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        print("🗑️ Clearing ReverseGeocoder cache...")
        
        // Clear memory caches
        cache.removeAll()
        enrichmentCache.removeAll()
        
        // Clear UserDefaults caches
        UserDefaults.standard.removeObject(forKey: "ReverseGeocoderCache")
        UserDefaults.standard.removeObject(forKey: "ReverseGeocoderEnrichmentCache")
        
        // Reset state
        currentLocationInfo = nil
        lastGeocodedLocation = nil
        
        print("✅ ReverseGeocoder cache cleared successfully")
    }
}

// MARK: - Cache Model
private struct CachedLocationInfo: Codable {
    let latitude: Double
    let longitude: Double
    let country: String?
    let city: String?
    let district: String?
    let timestamp: Date
}

// MARK: - Geographic Info Model (YENİ)
struct GeographicInfo: Codable {
    let city: String?
    let district: String?
    let country: String?
    let countryCode: String?
} 