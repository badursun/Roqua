import Foundation
import CoreLocation

struct VisitedRegion: Identifiable, Codable {
    // Primary data
    var id: Int64?                    // SQLite auto-increment
    var latitude: Double              // Merkez koordinat
    var longitude: Double
    var radius: Int                   // Keşif radius'u (metre)
    
    // Temporal data
    var timestampStart: Date          // İlk ziyaret
    var timestampEnd: Date?           // Son ziyaret (opsiyonel)
    var visitCount: Int               // Kaç kez ziyaret edildi
    
    // Geographic enrichment
    var city: String?                 // Şehir (reverse geocoding)
    var district: String?             // İlçe
    var country: String?              // Ülke
    var countryCode: String?          // TR, US, etc.
    
    // Optimization
    var geohash: String?              // 7-8 karakter grid
    var accuracy: Double?             // GPS accuracy
    
    // Computed properties
    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var isEnriched: Bool {
        city != nil && country != nil
    }
    
    // Initialize with defaults
    init(
        id: Int64? = nil,
        latitude: Double,
        longitude: Double,
        radius: Int = 200,
        timestampStart: Date = Date(),
        timestampEnd: Date? = nil,
        visitCount: Int = 1,
        city: String? = nil,
        district: String? = nil,
        country: String? = nil,
        countryCode: String? = nil,
        geohash: String? = nil,
        accuracy: Double? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.timestampStart = timestampStart
        self.timestampEnd = timestampEnd
        self.visitCount = visitCount
        self.city = city
        self.district = district
        self.country = country
        self.countryCode = countryCode
        self.geohash = geohash
        self.accuracy = accuracy
    }
}

// MARK: - Location Extensions
extension VisitedRegion {
    func distance(to location: CLLocation) -> CLLocationDistance {
        let center = CLLocation(latitude: latitude, longitude: longitude)
        return center.distance(from: location)
    }
    
    func contains(location: CLLocation) -> Bool {
        return distance(to: location) <= Double(radius)
    }
    
    func overlaps(with other: VisitedRegion) -> Bool {
        let distance = CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
        return distance < Double(radius + other.radius)
    }
    
    func expandToInclude(location: CLLocation) -> VisitedRegion {
        let currentCenter = CLLocation(latitude: latitude, longitude: longitude)
        let distance = currentCenter.distance(from: location)
        
        // Expand radius to include new location with buffer
        let newRadius = max(radius, Int(distance) + 50)
        
        var expanded = self
        expanded.radius = newRadius
        expanded.visitCount += 1
        expanded.timestampEnd = Date()
        
        return expanded
    }
}

// MARK: - Statistics
extension VisitedRegion {
    var areaSquareMeters: Double {
        return Double(radius * radius) * .pi
    }
    
    var formattedArea: String {
        let area = areaSquareMeters
        if area > 1_000_000 {
            return String(format: "%.2f km²", area / 1_000_000)
        } else {
            return String(format: "%.0f m²", area)
        }
    }
    
    var locationDescription: String {
        var parts: [String] = []
        
        if let district = district {
            parts.append(district)
        }
        if let city = city {
            parts.append(city)
        }
        if let country = country {
            parts.append(country)
        }
        
        return parts.isEmpty ? "Bilinmeyen Konum" : parts.joined(separator: ", ")
    }
} 