# 🗺️ Roqua Uygulaması - Detaylı Sistem Analizi

**Versiyon:** 1.0  
**Tarih:** 15 Ocak 2025  
**Platform:** iOS (SwiftUI + MapKit)  

---

## 📊 **EXECUTİVE SUMMARY**

Roqua, kullanıcının fiziksel hareketlerini takip ederek keşfettiği alanları harita üzerinde "Fog of War" sistemiyle görselleştiren bir iOS uygulamasıdır. Uygulama **persistent storage**, **real-time achievement tracking**, **reverse geocoding** ve **grid-based exploration analytics** özelliklerini içeren karmaşık bir veri işleme altyapısına sahiptir.

### **Temel Mimari**
- **Pattern:** MVVM + Event-Driven Architecture
- **Storage:** Dual storage (UserDefaults + SQLite)
- **Location:** CoreLocation + Background Processing
- **UI:** SwiftUI + MapKit Overlays
- **Analytics:** Grid-based world exploration percentage

---

## 🏗️ **SİSTEM ARKİTEKTÜRÜ**

### **1. Ana Bileşenler**

```
UI Layer (SwiftUI)
├── ContentView - Ana koordinatör
├── FogOfWarMapView - Harita overlay sistemi
├── BottomControlPanel - Real-time istatistikler
├── SettingsView - Kullanıcı ayarları
└── AchievementView - Gamification UI

Manager Layer (Business Logic)
├── LocationManager - Konum takibi
├── ExploredCirclesManager - Fog of War koordinatları
├── VisitedRegionManager - Database operations
├── GridHashManager - Dünya yüzdesi analytics
├── ReverseGeocoder - Coğrafi bilgi enrichment
└── AchievementManager - Gamification logic

Data Layer
├── UserDefaults - Hızlı cache storage
├── SQLite Database - Persistent regions data
└── EventBus - Manager arası koordinasyon
```

### **2. Veri Akış Pipeline**

**Location → Processing → Storage → UI Update**

1. **CoreLocation:** GPS koordinat alır
2. **LocationManager:** Significant change filtreler (50m+ mesafe, 50m+ accuracy)
3. **3 Paralel İşlem:**
   - ExploredCirclesManager → UserDefaults → Fog of War UI
   - VisitedRegionManager → SQLite → Achievement trigger
   - ReverseGeocoder → Cache → Coğrafi enrichment
4. **EventBus:** Manager'lar arası event broadcast
5. **UI:** @Published değişkenler ile auto-update

---

## 💾 **VERİ KATMANI**

### **1. UserDefaults Storage (Fast Access)**

```swift
// ExploredCirclesManager - Fog of War
"exploredCircles": [[String: Double]] 
// [{"latitude": 41.0082, "longitude": 28.9784}, ...]

// GridHashManager - Dünya yüzdesi
"visitedGridHashes": [String] 
// ["1234_5678", "1235_5679", ...]

// AchievementManager - Progress tracking
"achievementProgress": [String: AchievementProgress]
"unlockedAchievements": [String]

// AppSettings - Kullanıcı tercihleri (20+ ayar)
"locationTrackingDistance": 50.0      // Minimum hareket mesafesi
"explorationRadius": 150.0            // Keşif dairesi radius'u
"clusteringRadius": 75.0              // Overlap threshold
"percentageDecimals": 5               // Yüzde hassasiyeti
```

### **2. SQLite Database (Persistent Storage)**

```sql
CREATE TABLE visited_regions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    radius INTEGER NOT NULL DEFAULT 200,
    timestamp_start TEXT NOT NULL,
    timestamp_end TEXT,
    visit_count INTEGER NOT NULL DEFAULT 1,
    city TEXT,                    -- Reverse geocoding sonucu
    district TEXT,
    country TEXT,
    country_code TEXT,
    geohash TEXT,                 -- Spatial optimization
    accuracy REAL,                -- GPS accuracy
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Performance İndeksleri
CREATE INDEX idx_regions_location ON visited_regions(latitude, longitude);
CREATE INDEX idx_regions_geohash ON visited_regions(geohash);
CREATE INDEX idx_regions_timestamp ON visited_regions(timestamp_start);
CREATE INDEX idx_regions_country ON visited_regions(country);
```

### **3. Ana Veri Modeli**

```swift
struct VisitedRegion: Identifiable, Codable {
    var id: Int64?                    // SQLite auto-increment
    var latitude: Double              // Merkez koordinat
    var longitude: Double
    var radius: Int                   // Keşif radius'u (150m default)
    var timestampStart: Date          // İlk ziyaret
    var timestampEnd: Date?           // Son ziyaret (optional)
    var visitCount: Int               // Kaç kez ziyaret edildi
    var city: String?                 // Reverse geocoding
    var district: String?
    var country: String?
    var countryCode: String?
    var geohash: String?              // Grid optimization
    var accuracy: Double?             // GPS accuracy
}
```

---

## 🌍 **KONUM TAKIP SİSTEMİ**

### **1. LocationManager Workflow**

```swift
// 1. İzin Kontrolü
CLLocationManager.requestAlwaysAuthorization()

// 2. Location Updates Başlat
locationManager.startUpdatingLocation()

// 3. Significant Change Detection
func shouldProcessLocation(_ location: CLLocation) -> Bool {
    guard location.horizontalAccuracy <= 50.0 && location.horizontalAccuracy > 0 else { 
        return false // Accuracy threshold
    }
    
    if let lastLocation = lastProcessedLocation {
        let distance = location.distance(from: lastLocation)
        return distance >= 50.0 // Distance threshold
    }
    return true
}

// 4. Event Trigger
eventBus.publish(locationEvent: .significantLocationChange(location))
```

### **2. Location Processing Pipeline**

**ContentView.swift onChange Handler:**
```swift
.onChange(of: locationManager.significantLocationChange) { _, newLocation in
    if let location = newLocation {
        // PARALEL İŞLEMLER:
        
        // 1. Fog of War (Memory Storage)
        exploredCirclesManager.addLocation(location)
        
        // 2. Database & Achievements (SQLite)
        visitedRegionManager.processNewLocation(location)
        
        // 3. Geographic Info (Cache + Background)
        reverseGeocoder.geocodeLocation(location)
    }
}
```

### **3. Background Processing**

- **Always Authorization** ile arka plan çalışma
- **Significant Location Changes** ile battery optimization
- **5 saniye throttling** ile excessive processing önleme
- **Background thread** ile UI blocking önleme

---

## 🎨 **FOG OF WAR SİSTEMİ**

### **1. Render Algoritması**

```swift
class FogOfWarRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // 1. Siyah fog layer çiz (alpha=0.7)
        context.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
        context.fill(drawRect)
        
        // 2. Clear blend mode'a geç
        context.setBlendMode(.clear)
        
        // 3. Her keşfedilmiş koordinat için:
        for coordinate in overlay.exploredCircles {
            // Coordinate → MapPoint → Pixel conversion
            let radiusInMeters = overlay.radius                // 150m
            let metersPerMapPoint = MKMapPointsPerMeterAtLatitude(coordinate.latitude)
            let radiusInMapPoints = radiusInMeters * metersPerMapPoint
            let radiusInPixels = CGFloat(radiusInMapPoints) / CGFloat(mapRect.size.width) * drawRect.width
            
            // Daire çiz (şeffaf = fog kaldır)
            context.fillEllipse(in: circleRect)
        }
    }
}
```

### **2. Overlap Detection**

```swift
func addLocation(_ location: CLLocation) {
    let minimumDistance = settings.explorationRadius * 0.5 // 75m threshold
    
    // Mevcut dairelerle overlap kontrolü
    for existingCoordinate in exploredCircles {
        let existingLocation = CLLocation(latitude: existingCoordinate.latitude, 
                                        longitude: existingCoordinate.longitude)
        if location.distance(from: existingLocation) < minimumDistance {
            return // Skip - çok yakın
        }
    }
    
    // Yeni daire ekle
    exploredCircles.append(location.coordinate)
    saveToStorage() // UserDefaults persistence
}
```

---

## 📊 **WORLD EXPLORATION ANALYTİCS**

### **1. Grid-Based Hesaplama**

```swift
class GridHashManager {
    private var visitedGrids: Set<String> = []
    
    func register(region: VisitedRegion) {
        let newHashes = gridHashes(for: region)
        visitedGrids.formUnion(newHashes)
        updateExplorationStats()
    }
    
    private func calculateTotalWorldGrids() -> Double {
        let explorationRadius = 150.0               // Settings
        let gridSizeMeters = explorationRadius / 2.0  // 75m grid
        let gridSizeDegrees = gridSizeMeters / 111_000.0
        
        let latSteps = 180.0 / gridSizeDegrees      // -90° to +90°
        let lonSteps = 360.0 / gridSizeDegrees      // -180° to +180°
        return latSteps * lonSteps                   // Total world grids
    }
    
    private func updateExplorationStats() {
        explorationPercentage = (Double(visitedGrids.count) / calculateTotalWorldGrids()) * 100.0
        formattedPercentage = String(format: "%.\(settings.percentageDecimals)f", explorationPercentage)
    }
}
```

### **2. Grid Hash Algoritması**

Region'ın kapladığı grid hücrelerini hesaplar:

```swift
private func gridHashes(for region: VisitedRegion) -> Set<String> {
    let gridSizeMeters = 75.0 // explorationRadius / 2
    let steps = Int(ceil(Double(region.radius) / gridSizeMeters)) + 1
    
    for latOffset in -steps...steps {
        for lonOffset in -steps...steps {
            let lat = region.latitude + (Double(latOffset) * gridSizeDegrees)
            let lon = region.longitude + (Double(lonOffset) * gridSizeDegrees)
            
            if point.distance(from: center) <= Double(region.radius) {
                result.insert("\(latIndex)_\(lonIndex)")
            }
        }
    }
}
```

**Sonuç:** Dünya yüzde hesaplaması = (Ziyaret edilen grid sayısı / Toplam dünya grid sayısı) × 100

---

## 🗃️ **VERİTABANI SİSTEMİ**

### **1. SQLiteManager Architecture**

```swift
class SQLiteManager {
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.roqua.sqlite", qos: .utility)
    
    // Performance optimizations
    init() {
        sqlite3_exec(db, "PRAGMA journal_mode = WAL", nil, nil, nil)      // Write-Ahead Logging
        sqlite3_exec(db, "PRAGMA synchronous = NORMAL", nil, nil, nil)    // Balanced durability
        sqlite3_exec(db, "PRAGMA cache_size = 10000", nil, nil, nil)      // Memory cache
        sqlite3_exec(db, "PRAGMA temp_store = MEMORY", nil, nil, nil)     // Temp tables in RAM
    }
}
```

### **2. CRUD Operations**

**Insert (High-frequency):**
```swift
func insertVisitedRegion(_ region: VisitedRegion) -> Int64? {
    return dbQueue.sync {
        let insertSQL = """
            INSERT INTO visited_regions 
            (latitude, longitude, radius, timestamp_start, visit_count, city, country)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        // Prepared statement execution
        return sqlite3_last_insert_rowid(db)
    }
}
```

**Spatial Query (Optimized):**
```swift
func getVisitedRegionsNear(latitude: Double, longitude: Double, radiusKm: Double) -> [VisitedRegion] {
    // Bounding box hesaplama
    let latDelta = radiusKm / 111.0
    let lngDelta = radiusKm / (111.0 * cos(latitude * .pi / 180.0))
    
    let querySQL = """
        SELECT * FROM visited_regions 
        WHERE latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?
        ORDER BY timestamp_start DESC;
    """
    // Index-optimized range query
}
```

---

Bu analizin devamı için ikinci dosya oluşturmalıyım... 