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
    
    private init() {
        loadCacheFromUserDefaults()
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