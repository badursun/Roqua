# 🗺️ Roqua - VisitedRegion Sistemi Yol Haritası

## 🎯 **GENEL HEDEF**

Mevcut `ExploredCirclesManager` sisteminden gelişmiş `VisitedRegion` sistemine geçiş yaparak:
- **Persistent storage** (SQLite)
- **Coğrafi zenginleştirme** (reverse geocoding)
- **Oyunlaştırma altyapısı** (bölgesel istatistikler)
- **Performance optimizasyonu** (smart clustering)

---

## 📊 **MEVCUT DURUM ANALİZİ**

### ✅ **Başarıyla Tamamlanan**
- Fog of War overlay sistemi çalışıyor
- Real-time location tracking aktif
- 200m radius keşif alanları
- 10m minimum distance filtering
- MapKit entegrasyonu mükemmel

### 🔄 **Geçiş Gereken Alanlar**
- `[CLLocationCoordinate2D]` → `[VisitedRegion]`
- Memory storage → SQLite persistence
- Simple coordinates → Rich geographic data
- Basic rendering → Intelligent clustering

---

## 🏗️ **FAZ 1: MODÜLER YAPI REORGANIZASYONU**

### **1.1 Dosya Yapısı Yeniden Düzenleme**

**Hedef Yapı:**
```
Roqua/
├── Models/
│   ├── VisitedRegion.swift          ← Yeni ana model
│   ├── LocationData.swift           ← Yardımcı veri yapıları
│   └── Achievement.swift            ← Gelecek için
├── Managers/
│   ├── LocationManager.swift        ← Mevcut (düzenlenecek)
│   ├── VisitedRegionManager.swift   ← Yeni ana manager
│   ├── ReverseGeocoder.swift        ← Coğrafi veri
│   └── GeoHashHelper.swift          ← Optimizasyon
├── Database/
│   ├── SQLiteManager.swift          ← Database operations
│   └── DatabaseMigration.swift      ← Schema updates
├── Views/
│   ├── ContentView.swift            ← Mevcut (güncellenecek)
│   ├── MapView/
│   │   ├── FogOfWarMapView.swift    ← Mevcut (refactor)
│   │   └── RegionOverlayView.swift  ← Yeni overlay system
│   └── Components/
│       ├── StatsView.swift          ← İstatistikler
│       └── AchievementView.swift    ← Rozetler
└── Extensions/
    ├── CLLocation+Extensions.swift   ← Yardımcı fonksiyonlar
    └── MKMapView+Regions.swift      ← Harita extensions
```

### **1.2 Dependency Management**
```swift
// Package.swift dependencies
dependencies: [
    .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.14.1"),
    .package(url: "https://github.com/malcommac/SwiftLocation", from: "5.2.0"), // opsiyonel
]
```

---

## 💾 **FAZ 2: VISITEDREGION MODEL & SQLITE**

### **2.1 VisitedRegion Model**

```swift
import Foundation
import CoreLocation
import SQLite

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
}

// Extensions
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
}
```

### **2.2 SQLite Schema**

```sql
-- Main regions table
CREATE TABLE visited_regions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    radius INTEGER NOT NULL DEFAULT 200,
    timestamp_start TEXT NOT NULL,
    timestamp_end TEXT,
    visit_count INTEGER NOT NULL DEFAULT 1,
    city TEXT,
    district TEXT,
    country TEXT,
    country_code TEXT,
    geohash TEXT,
    accuracy REAL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_regions_location ON visited_regions(latitude, longitude);
CREATE INDEX idx_regions_geohash ON visited_regions(geohash);
CREATE INDEX idx_regions_country ON visited_regions(country);
CREATE INDEX idx_regions_timestamp ON visited_regions(timestamp_start);

-- Statistics table (for quick queries)
CREATE TABLE region_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stat_type TEXT NOT NULL, -- 'country', 'city', 'district'
    stat_name TEXT NOT NULL, -- 'Turkey', 'Istanbul', 'Kadıköy'
    region_count INTEGER NOT NULL DEFAULT 0,
    total_area REAL NOT NULL DEFAULT 0.0,
    first_visit TEXT,
    last_visit TEXT,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_stats_type_name ON region_stats(stat_type, stat_name);
```

### **2.3 SQLiteManager Implementation**

```swift
import SQLite
import Foundation

class SQLiteManager {
    static let shared = SQLiteManager()
    private var db: Connection?
    
    // Table definitions
    private let regionsTable = Table("visited_regions")
    private let statsTable = Table("region_stats")
    
    // Column definitions
    private let id = Expression<Int64>("id")
    private let latitude = Expression<Double>("latitude")
    private let longitude = Expression<Double>("longitude")
    private let radius = Expression<Int>("radius")
    private let timestampStart = Expression<String>("timestamp_start")
    private let timestampEnd = Expression<String?>("timestamp_end")
    private let visitCount = Expression<Int>("visit_count")
    private let city = Expression<String?>("city")
    private let district = Expression<String?>("district")
    private let country = Expression<String?>("country")
    private let countryCode = Expression<String?>("country_code")
    private let geohash = Expression<String?>("geohash")
    private let accuracy = Expression<Double?>("accuracy")
    private let createdAt = Expression<String>("created_at")
    private let updatedAt = Expression<String>("updated_at")
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let dbPath = "\(documentsPath)/roqua.sqlite3"
            db = try Connection(dbPath)
            createTables()
            print("📊 SQLite database initialized at: \(dbPath)")
        } catch {
            print("❌ Database setup error: \(error)")
        }
    }
    
    private func createTables() {
        do {
            try db?.run(regionsTable.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(latitude)
                t.column(longitude)
                t.column(radius, defaultValue: 200)
                t.column(timestampStart)
                t.column(timestampEnd)
                t.column(visitCount, defaultValue: 1)
                t.column(city)
                t.column(district)
                t.column(country)
                t.column(countryCode)
                t.column(geohash)
                t.column(accuracy)
                t.column(createdAt, defaultValue: Date().iso8601String)
                t.column(updatedAt, defaultValue: Date().iso8601String)
            })
            
            // Create indexes
            try db?.run("CREATE INDEX IF NOT EXISTS idx_regions_location ON visited_regions(latitude, longitude)")
            try db?.run("CREATE INDEX IF NOT EXISTS idx_regions_geohash ON visited_regions(geohash)")
            
            print("✅ Database tables created successfully")
        } catch {
            print("❌ Table creation error: \(error)")
        }
    }
    
    // CRUD Operations
    func insertRegion(_ region: VisitedRegion) -> Int64? {
        do {
            let insert = regionsTable.insert(
                latitude <- region.latitude,
                longitude <- region.longitude,
                radius <- region.radius,
                timestampStart <- region.timestampStart.iso8601String,
                timestampEnd <- region.timestampEnd?.iso8601String,
                visitCount <- region.visitCount,
                city <- region.city,
                district <- region.district,
                country <- region.country,
                countryCode <- region.countryCode,
                geohash <- region.geohash,
                accuracy <- region.accuracy,
                updatedAt <- Date().iso8601String
            )
            
            let rowId = try db?.run(insert)
            print("✅ Region inserted with ID: \(rowId ?? -1)")
            return rowId
        } catch {
            print("❌ Insert error: \(error)")
            return nil
        }
    }
    
    func fetchAllRegions() -> [VisitedRegion] {
        var regions: [VisitedRegion] = []
        
        do {
            guard let db = db else { return regions }
            
            for row in try db.prepare(regionsTable) {
                let region = VisitedRegion(
                    id: row[id],
                    latitude: row[latitude],
                    longitude: row[longitude],
                    radius: row[radius],
                    timestampStart: Date.fromISO8601(row[timestampStart]) ?? Date(),
                    timestampEnd: row[timestampEnd] != nil ? Date.fromISO8601(row[timestampEnd]!) : nil,
                    visitCount: row[visitCount],
                    city: row[city],
                    district: row[district],
                    country: row[country],
                    countryCode: row[countryCode],
                    geohash: row[geohash],
                    accuracy: row[accuracy]
                )
                regions.append(region)
            }
        } catch {
            print("❌ Fetch error: \(error)")
        }
        
        return regions
    }
    
    func fetchRegionsNearLocation(_ location: CLLocation, radius: Double = 1000) -> [VisitedRegion] {
        // Implement spatial query with bounding box
        let latDelta = radius / 111000 // Approximate degrees per meter
        let lngDelta = radius / (111000 * cos(location.coordinate.latitude * .pi / 180))
        
        let minLat = location.coordinate.latitude - latDelta
        let maxLat = location.coordinate.latitude + latDelta
        let minLng = location.coordinate.longitude - lngDelta
        let maxLng = location.coordinate.longitude + lngDelta
        
        var regions: [VisitedRegion] = []
        
        do {
            guard let db = db else { return regions }
            
            let query = regionsTable.filter(
                latitude >= minLat && latitude <= maxLat &&
                longitude >= minLng && longitude <= maxLng
            )
            
            for row in try db.prepare(query) {
                let region = VisitedRegion(
                    id: row[id],
                    latitude: row[latitude],
                    longitude: row[longitude],
                    radius: row[radius],
                    timestampStart: Date.fromISO8601(row[timestampStart]) ?? Date(),
                    timestampEnd: row[timestampEnd] != nil ? Date.fromISO8601(row[timestampEnd]!) : nil,
                    visitCount: row[visitCount],
                    city: row[city],
                    district: row[district],
                    country: row[country],
                    countryCode: row[countryCode],
                    geohash: row[geohash],
                    accuracy: row[accuracy]
                )
                regions.append(region)
            }
        } catch {
            print("❌ Spatial query error: \(error)")
        }
        
        return regions
    }
    
    func updateRegionGeography(_ regionId: Int64, city: String?, district: String?, country: String?, countryCode: String?) {
        do {
            let region = regionsTable.filter(id == regionId)
            try db?.run(region.update(
                self.city <- city,
                self.district <- district,
                self.country <- country,
                self.countryCode <- countryCode,
                updatedAt <- Date().iso8601String
            ))
            print("✅ Region \(regionId) geography updated")
        } catch {
            print("❌ Update error: \(error)")
        }
    }
    
    func getRegionStats() -> (totalRegions: Int, totalCountries: Int, totalCities: Int) {
        do {
            guard let db = db else { return (0, 0, 0) }
            
            let totalRegions = try db.scalar(regionsTable.count)
            let totalCountries = try db.scalar(regionsTable.select(country.distinct).count)
            let totalCities = try db.scalar(regionsTable.select(city.distinct).count)
            
            return (totalRegions, totalCountries, totalCities)
        } catch {
            print("❌ Stats query error: \(error)")
            return (0, 0, 0)
        }
    }
}

// Date extensions for ISO8601
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    static func fromISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}
```

---

## 🧠 **FAZ 3: VISITEDREGIONMANAGER**

### **3.1 Smart Clustering Algorithm**

```swift
import Foundation
import CoreLocation

class VisitedRegionManager: ObservableObject {
    static let shared = VisitedRegionManager()
    
    @Published var visitedRegions: [VisitedRegion] = []
    
    private let database = SQLiteManager.shared
    private let reverseGeocoder = ReverseGeocoder.shared
    private let geoHashHelper = GeoHashHelper.shared
    
    // Configuration
    private let defaultRadius: Int = 200
    private let minimumDistance: Double = 100.0 // Smart clustering threshold
    private let maxRegionsInMemory: Int = 1000
    
    private init() {
        loadRegionsFromDatabase()
    }
    
    // MARK: - Main Location Processing
    func handleNewLocation(_ location: CLLocation) {
        // 1. Check if location is within existing region
        if let existingRegion = findContainingRegion(for: location) {
            updateExistingRegion(existingRegion, with: location)
            return
        }
        
        // 2. Check if location is close enough to merge
        if let nearbyRegion = findNearbyRegion(for: location) {
            expandRegion(nearbyRegion, to: location)
            return
        }
        
        // 3. Create new region
        createNewRegion(at: location)
    }
    
    private func findContainingRegion(for location: CLLocation) -> VisitedRegion? {
        return visitedRegions.first { region in
            region.contains(location: location)
        }
    }
    
    private func findNearbyRegion(for location: CLLocation) -> VisitedRegion? {
        return visitedRegions.first { region in
            let distance = region.distance(to: location)
            return distance <= minimumDistance && distance > Double(region.radius)
        }
    }
    
    private func updateExistingRegion(_ region: VisitedRegion, with location: CLLocation) {
        // Update visit count and timestamp
        var updatedRegion = region
        updatedRegion.visitCount += 1
        updatedRegion.timestampEnd = Date()
        
        // Update in database
        if let regionId = region.id {
            database.updateRegionVisit(regionId, visitCount: updatedRegion.visitCount, lastVisit: Date())
        }
        
        // Update in memory
        if let index = visitedRegions.firstIndex(where: { $0.id == region.id }) {
            visitedRegions[index] = updatedRegion
        }
        
        print("🔄 Updated existing region \(region.id ?? -1), visit count: \(updatedRegion.visitCount)")
    }
    
    private func expandRegion(_ region: VisitedRegion, to location: CLLocation) {
        // Calculate new center and radius to include both points
        let currentCenter = CLLocation(latitude: region.latitude, longitude: region.longitude)
        let distance = currentCenter.distance(from: location)
        
        // Expand radius to include new location with some buffer
        let newRadius = max(region.radius, Int(distance) + 50)
        
        var expandedRegion = region
        expandedRegion.radius = newRadius
        expandedRegion.visitCount += 1
        expandedRegion.timestampEnd = Date()
        
        // Update in database
        if let regionId = region.id {
            database.updateRegionExpansion(regionId, newRadius: newRadius, visitCount: expandedRegion.visitCount, lastVisit: Date())
        }
        
        // Update in memory
        if let index = visitedRegions.firstIndex(where: { $0.id == region.id }) {
            visitedRegions[index] = expandedRegion
        }
        
        print("📈 Expanded region \(region.id ?? -1) to radius: \(newRadius)m")
    }
    
    private func createNewRegion(at location: CLLocation) {
        let geohash = geoHashHelper.encode(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            precision: 7
        )
        
        var newRegion = VisitedRegion(
            id: nil,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: defaultRadius,
            timestampStart: Date(),
            timestampEnd: nil,
            visitCount: 1,
            city: nil,
            district: nil,
            country: nil,
            countryCode: nil,
            geohash: geohash,
            accuracy: location.horizontalAccuracy
        )
        
        // Save to database
        if let regionId = database.insertRegion(newRegion) {
            newRegion.id = regionId
            
            // Add to memory (with limit)
            addRegionToMemory(newRegion)
            
            // Start reverse geocoding in background
            reverseGeocoder.enrichRegion(newRegion) { [weak self] enrichedRegion in
                self?.updateRegionGeography(enrichedRegion)
            }
            
            print("✨ Created new region \(regionId) at \(location.coordinate)")
        }
    }
    
    private func addRegionToMemory(_ region: VisitedRegion) {
        visitedRegions.append(region)
        
        // Limit memory usage
        if visitedRegions.count > maxRegionsInMemory {
            // Remove oldest regions (keep most recent)
            visitedRegions = Array(visitedRegions.suffix(maxRegionsInMemory))
        }
    }
    
    private func updateRegionGeography(_ enrichedRegion: VisitedRegion) {
        // Update database
        if let regionId = enrichedRegion.id {
            database.updateRegionGeography(
                regionId,
                city: enrichedRegion.city,
                district: enrichedRegion.district,
                country: enrichedRegion.country,
                countryCode: enrichedRegion.countryCode
            )
        }
        
        // Update memory
        if let index = visitedRegions.firstIndex(where: { $0.id == enrichedRegion.id }) {
            visitedRegions[index] = enrichedRegion
        }
        
        print("🌍 Enriched region \(enrichedRegion.id ?? -1): \(enrichedRegion.city ?? "Unknown"), \(enrichedRegion.country ?? "Unknown")")
    }
    
    // MARK: - Data Loading
    private func loadRegionsFromDatabase() {
        let allRegions = database.fetchAllRegions()
        
        // Load recent regions into memory
        visitedRegions = Array(allRegions.suffix(maxRegionsInMemory))
        
        print("📊 Loaded \(visitedRegions.count) regions into memory (total: \(allRegions.count))")
    }
    
    func loadRegionsForMapView(center: CLLocation, radius: Double = 5000) -> [VisitedRegion] {
        return database.fetchRegionsNearLocation(center, radius: radius)
    }
    
    // MARK: - Statistics
    func getExplorationStats() -> ExplorationStats {
        let stats = database.getRegionStats()
        let totalArea = visitedRegions.reduce(0.0) { total, region in
            total + (Double(region.radius * region.radius) * .pi)
        }
        
        return ExplorationStats(
            totalRegions: stats.totalRegions,
            totalCountries: stats.totalCountries,
            totalCities: stats.totalCities,
            totalAreaSquareMeters: totalArea,
            worldPercentage: (totalArea / 510_072_000_000_000) * 100 // Earth's surface area
        )
    }
}

struct ExplorationStats {
    let totalRegions: Int
    let totalCountries: Int
    let totalCities: Int
    let totalAreaSquareMeters: Double
    let worldPercentage: Double
    
    var formattedArea: String {
        if totalAreaSquareMeters > 1_000_000 {
            return String(format: "%.1f km²", totalAreaSquareMeters / 1_000_000)
        } else {
            return String(format: "%.0f m²", totalAreaSquareMeters)
        }
    }
    
    var formattedPercentage: String {
        return String(format: "%.6f%%", worldPercentage)
    }
}
```

---

## 🌍 **FAZ 4: REVERSE GEOCODING**

### **4.1 ReverseGeocoder Manager**

```swift
import CoreLocation
import Foundation

class ReverseGeocoder {
    static let shared = ReverseGeocoder()
    
    private let geocoder = CLGeocoder()
    private let cache = NSCache<NSString, GeographicInfo>()
    private let queue = DispatchQueue(label: "reverse-geocoding", qos: .utility)
    
    private init() {
        cache.countLimit = 1000
    }
    
    func enrichRegion(_ region: VisitedRegion, completion: @escaping (VisitedRegion) -> Void) {
        let location = CLLocation(latitude: region.latitude, longitude: region.longitude)
        let cacheKey = "\(region.latitude),\(region.longitude)" as NSString
        
        // Check cache first
        if let cachedInfo = cache.object(forKey: cacheKey) {
            var enrichedRegion = region
            enrichedRegion.city = cachedInfo.city
            enrichedRegion.district = cachedInfo.district
            enrichedRegion.country = cachedInfo.country
            enrichedRegion.countryCode = cachedInfo.countryCode
            
            DispatchQueue.main.async {
                completion(enrichedRegion)
            }
            return
        }
        
        // Perform reverse geocoding
        queue.async { [weak self] in
            self?.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                var enrichedRegion = region
                
                if let placemark = placemarks?.first, error == nil {
                    let info = GeographicInfo(
                        city: placemark.administrativeArea,
                        district: placemark.subAdministrativeArea,
                        country: placemark.country,
                        countryCode: placemark.isoCountryCode
                    )
                    
                    // Cache the result
                    self?.cache.setObject(info, forKey: cacheKey)
                    
                    // Update region
                    enrichedRegion.city = info.city
                    enrichedRegion.district = info.district
                    enrichedRegion.country = info.country
                    enrichedRegion.countryCode = info.countryCode
                    
                    print("🌍 Geocoded: \(info.city ?? "Unknown"), \(info.country ?? "Unknown")")
                } else {
                    print("⚠️ Geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                }
                
                DispatchQueue.main.async {
                    completion(enrichedRegion)
                }
            }
        }
    }
    
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
}

class GeographicInfo: NSObject {
    let city: String?
    let district: String?
    let country: String?
    let countryCode: String?
    
    init(city: String?, district: String?, country: String?, countryCode: String?) {
        self.city = city
        self.district = district
        self.country = country
        self.countryCode = countryCode
    }
}
```

---

## 🔧 **FAZ 5: GEOHASH OPTIMIZASYONU**

### **5.1 GeoHashHelper**

```swift
import Foundation
import CoreLocation

class GeoHashHelper {
    static let shared = GeoHashHelper()
    
    private let base32 = "0123456789bcdefghjkmnpqrstuvwxyz"
    
    private init() {}
    
    func encode(latitude: Double, longitude: Double, precision: Int = 7) -> String {
        var latRange = (-90.0, 90.0)
        var lngRange = (-180.0, 180.0)
        
        var geohash = ""
        var bits = 0
        var bit = 0
        var even = true
        
        while geohash.count < precision {
            if even {
                // Longitude
                let mid = (lngRange.0 + lngRange.1) / 2
                if longitude >= mid {
                    bit = (bit << 1) | 1
                    lngRange.0 = mid
                } else {
                    bit = bit << 1
                    lngRange.1 = mid
                }
            } else {
                // Latitude
                let mid = (latRange.0 + latRange.1) / 2
                if latitude >= mid {
                    bit = (bit << 1) | 1
                    latRange.0 = mid
                } else {
                    bit = bit << 1
                    latRange.1 = mid
                }
            }
            
            even = !even
            bits += 1
            
            if bits == 5 {
                let index = base32.index(base32.startIndex, offsetBy: bit)
                geohash.append(base32[index])
                bits = 0
                bit = 0
            }
        }
        
        return geohash
    }
    
    func decode(_ geohash: String) -> (latitude: Double, longitude: Double) {
        var latRange = (-90.0, 90.0)
        var lngRange = (-180.0, 180.0)
        var even = true
        
        for char in geohash {
            guard let index = base32.firstIndex(of: char) else { continue }
            let value = base32.distance(from: base32.startIndex, to: index)
            
            for i in (0..<5).reversed() {
                let bit = (value >> i) & 1
                
                if even {
                    // Longitude
                    let mid = (lngRange.0 + lngRange.1) / 2
                    if bit == 1 {
                        lngRange.0 = mid
                    } else {
                        lngRange.1 = mid
                    }
                } else {
                    // Latitude
                    let mid = (latRange.0 + latRange.1) / 2
                    if bit == 1 {
                        latRange.0 = mid
                    } else {
                        latRange.1 = mid
                    }
                }
                
                even = !even
            }
        }
        
        return (
            latitude: (latRange.0 + latRange.1) / 2,
            longitude: (lngRange.0 + lngRange.1) / 2
        )
    }
    
    func neighbors(_ geohash: String) -> [String] {
        // Return neighboring geohash cells for clustering
        // Implementation would return 8 surrounding cells
        return []
    }
    
    func gridSize(precision: Int) -> (latitude: Double, longitude: Double) {
        // Calculate approximate grid size for given precision
        let latBits = precision * 5 / 2
        let lngBits = precision * 5 - latBits
        
        let latSize = 180.0 / pow(2.0, Double(latBits))
        let lngSize = 360.0 / pow(2.0, Double(lngBits))
        
        return (latitude: latSize, longitude: lngSize)
    }
}
```

---

## 🔄 **FAZ 6: MEVCUT SİSTEMDEN GEÇİŞ**

### **6.1 ExploredCirclesManager'dan Geçiş**

```swift
// ContentView.swift içinde geçiş
class MigrationManager {
    static func migrateExploredCirclesToVisitedRegions(_ circles: [CLLocationCoordinate2D]) {
        let visitedRegionManager = VisitedRegionManager.shared
        
        print("🔄 Starting migration of \(circles.count) explored circles...")
        
        for (index, coordinate) in circles.enumerated() {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            // Create VisitedRegion from coordinate
            let region = VisitedRegion(
                id: nil,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radius: 200, // Default radius
                timestampStart: Date().addingTimeInterval(-Double(circles.count - index) * 60), // Simulate timeline
                timestampEnd: nil,
                visitCount: 1,
                city: nil,
                district: nil,
                country: nil,
                countryCode: nil,
                geohash: GeoHashHelper.shared.encode(latitude: coordinate.latitude, longitude: coordinate.longitude),
                accuracy: 10.0
            )
            
            // Insert into database
            if let regionId = SQLiteManager.shared.insertRegion(region) {
                print("✅ Migrated circle \(index + 1)/\(circles.count) → Region ID: \(regionId)")
            }
        }
        
        // Reload regions
        visitedRegionManager.loadRegionsFromDatabase()
        
        print("🎉 Migration completed!")
    }
}
```

### **6.2 ContentView Güncellemesi**

```swift
// ContentView.swift'te değişiklikler
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var visitedRegionManager = VisitedRegionManager.shared
    @State private var position: MapCameraPosition = .automatic
    @State private var hasMigrated = false
    
    var body: some View {
        // ... existing UI code ...
        
        FogOfWarMapView(
            locationManager: locationManager,
            visitedRegions: visitedRegionManager.visitedRegions, // Changed from exploredCircles
            position: $position
        )
        .onAppear {
            if !hasMigrated {
                // One-time migration from old system
                // MigrationManager.migrateExploredCirclesToVisitedRegions(oldExploredCircles)
                hasMigrated = true
            }
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if let location = newLocation {
                visitedRegionManager.handleNewLocation(location) // Changed from exploredCirclesManager
            }
        }
    }
}
```

---

## 📊 **FAZ 7: İSTATİSTİK SİSTEMİ**

### **7.1 Statistics View**

```swift
import SwiftUI

struct ExplorationStatsView: View {
    @StateObject private var visitedRegionManager = VisitedRegionManager.shared
    @State private var stats: ExplorationStats?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let stats = stats {
                        // Overall Stats
                        StatsCardView(
                            title: "Toplam Keşif",
                            value: "\(stats.totalRegions)",
                            subtitle: "bölge",
                            icon: "map.fill"
                        )
                        
                        StatsCardView(
                            title: "Keşfedilen Alan",
                            value: stats.formattedArea,
                            subtitle: "toplam alan",
                            icon: "globe.europe.africa.fill"
                        )
                        
                        StatsCardView(
                            title: "Dünya Yüzdesi",
                            value: stats.formattedPercentage,
                            subtitle: "keşfedildi",
                            icon: "percent"
                        )
                        
                        // Geographic Breakdown
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Coğrafi Dağılım")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            HStack {
                                StatItemView(
                                    title: "Ülke",
                                    value: "\(stats.totalCountries)",
                                    color: .blue
                                )
                                
                                StatItemView(
                                    title: "Şehir",
                                    value: "\(stats.totalCities)",
                                    color: .green
                                )
                                
                                StatItemView(
                                    title: "Bölge",
                                    value: "\(stats.totalRegions)",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        ProgressView("İstatistikler yükleniyor...")
                    }
                }
                .padding()
            }
            .navigationTitle("Keşif İstatistikleri")
            .onAppear {
                loadStats()
            }
        }
    }
    
    private func loadStats() {
        stats = visitedRegionManager.getExplorationStats()
    }
}

struct StatsCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct StatItemView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}
```

---

## 🎯 **UYGULAMA SIRASI**

### **Hafta 1: Temel Altyapı**
1. ✅ Fog of War tamamlandı
2. 🔄 Dosya yapısı reorganizasyonu
3. 🔄 VisitedRegion model oluşturma
4. 🔄 SQLite kurulumu ve test

### **Hafta 2: Veri Geçişi**
1. 🔄 VisitedRegionManager implementasyonu
2. 🔄 Smart clustering algoritması
3. 🔄 ExploredCircles'dan geçiş
4. 🔄 Test ve debug

### **Hafta 3: Coğrafi Zenginleştirme**
1. 🔄 ReverseGeocoder implementasyonu
2. 🔄 GeoHash optimizasyonu
3. 🔄 Background processing
4. 🔄 Cache sistemi

### **Hafta 4: İstatistik ve UI**
1. 🔄 İstatistik hesaplama sistemi
2. 🔄 Stats UI implementasyonu
3. 🔄 Performance optimizasyonu
4. 🔄 Final testing

---

## 🚀 **BAŞARI KRİTERLERİ**

### **Teknik Hedefler**
- ✅ SQLite database çalışıyor
- ✅ Smart clustering algoritması aktif
- ✅ Reverse geocoding %80+ başarı oranı
- ✅ Memory usage < 100MB
- ✅ Database size < 10MB/1000 region

### **Kullanıcı Deneyimi**
- ✅ Fog of War sistemi korunuyor
- ✅ Real-time location tracking devam ediyor
- ✅ İstatistikler doğru hesaplanıyor
- ✅ App performance etkilenmiyor
- ✅ Offline çalışma korunuyor

### **Veri Kalitesi**
- ✅ %90+ regions coğrafi bilgi ile zenginleştirilmiş
- ✅ Duplicate regions < %5
- ✅ Clustering accuracy > %95
- ✅ Database integrity korunuyor

Bu yol haritası ile Roqua'yı basit bir fog of war uygulamasından gelişmiş bir coğrafi keşif ve oyunlaştırma platformuna dönüştüreceğiz! 🗺️✨ 