# Gelişmiş Fonksiyonlar
- İl / İlçe / Ülke tespiti (reverse geocoding)
- Her kayıt edilen konumda il/ilçe/ülke bilgisi kaydet
- SQLite yapısına city, district, country kolonlarını ekle
- Bölge Bazlı İstatistikler
- İstanbul’da kaç ilçe gezildi? (örneğin: 8/39)
- Türkiye’de kaç il gezildi? (örnek: 23/81)
- Ülke sayacı: 5 ülke gezildi

⸻

# Oyunlaştırma Sistemi (Gamification)
- Bölgesel başarımlar tanımla
- İstanbul’daki 39 ilçeyi gez → Fatih Madalyonu
- Türkiye’deki 81 ili gez → Anadolu Ustası Rozeti
- Avrupa kıtasında 10 ülke → Euro Explorer
- Yeni bir ilçeye ilk kez gir → Kaşif Puanı +1
- XP ve Seviye Sistemi
- Her gezilen yeni il/ilçe/ülke puan kazandırsın
- Rozetler ve başarımlar profil kartında biriksin

⸻

# Önemli Özellikler
- Tüm fonksiyonlar internet olmadan da çalışabilmeli
- File Structure yapısını düzenle: 
```
Roqua/
├── Models/
│   └── VisitedRegion.swift
│
├── Managers/
│   ├── LocationManager.swift          ← GPS takibi
│   ├── VisitedRegionManager.swift     ← Yeni bölge olup olmadığını belirler
│   ├── ReverseGeocoder.swift          ← Şehir, ilçe, ülke çevirisi
│   └── GeoHashHelper.swift            ← GeoHash kontrol (opsiyonel)
│
├── Database/
│   └── SQLiteManager.swift            ← Veritabanı CRUD işlemleri
│
├── Views/
│   └── MapViewController.swift        ← Haritayı gösteren ekran
│
├── Extensions/
│   └── MKMapView+Zoom.swift           ← Zoom seviyesi ölçümü (opsiyonel)
```
tek dosyada boğulmamak en iyisi. Projeyi hem sürdürülebilir hem de kolay işlenebilir hale getirmek için modüler yapıda olmalıi

# Reverse geocoding
🎯 Neden Reverse Geocoding?

Kullanıcı bir yerde yürüdü → sen sadece lat/lng alırsın
Ama:
👉 “İstanbul / Kadıköy / Türkiye” gibi anlamlı bilgiye ulaşman lazım.
İşte burada reverse geocoding devreye giriyor.

⚙️ Nasıl Çalışır?

Girdi:
latitude: 40.9879
longitude: 29.0281

Çıktı:
{
  "country": "Turkey",
  "administrativeArea": "Istanbul",
  "subAdministrativeArea": "Kadıköy"
}

⸻

🔧 iOS’ta Reverse Geocoding

iOS’ta CoreLocation + CLGeocoder ile tamamen offline çalışmaz, ama cihaz cache’i varsa internet olmadan da yanıt verebilir.

Örnek Swift kodu:

import CoreLocation

func getLocationInfo(from location: CLLocation, completion: @escaping (String?, String?, String?) -> Void) {
    let geocoder = CLGeocoder()
    geocoder.reverseGeocodeLocation(location) { placemarks, error in
        if let placemark = placemarks?.first {
            let country = placemark.country
            let city = placemark.administrativeArea
            let district = placemark.subAdministrativeArea
            completion(country, city, district)
        } else {
            completion(nil, nil, nil)
        }
    }
}


⸻

🌐 Alternatif: Harici Servisler (online)

Eğer daha detaylı istersen:
	•	Mapbox Geocoding API
	•	OpenStreetMap Nominatim
	•	Google Maps API

Ama bunlar:
	•	API key ister
	•	Veri gönderimi = gizlilik açığı yaratır
	•	Offline çalışmaz

⸻

🧠 Tavsiye

Roqua gizlilik odaklı olduğu için:
	•	iOS CLGeocoder kullan (cache’li çalışıyor)
	•	İnternet yoksa daireyi kaydet → sonra bağlantı gelince reverse geocode yap
	•	Her gezi noktasında “ülke / şehir / ilçe” verisini SQLite’a ekle

Mükemmel. iOS-only bir app yapıyorsan ve Apple Maps + CoreLocation kullanıyorsan, o zaman şu avantajlar seninle:

⸻

✅ Apple ekosisteminden maksimum fayda

📍 1. Arka Planda Konum Takibi
	•	CLLocationManager + allowsBackgroundLocationUpdates = true
	•	requestAlwaysAuthorization() ile 7/24 kayıt
	•	Düşük güç modunda bile çalışabiliyor

🌍 2. Apple Haritaları (MapKit)
	•	Tam native → pil tüketimi optimize
	•	Offline cache’i destekliyor
	•	Map overlay & annotation desteği ile keşif alanlarını çizmek kolay

🌐 3. CLGeocoder ile Reverse Geocoding
	•	Ekstra API yok, gizlilik senin kontrolünde
	•	iOS cihaz önceden bu bölgede bulunmuşsa offline bile çözümleme yapabiliyor
	•	Placemark objesi ile direkt ülke, şehir, ilçe bilgisi geliyor

⸻

🔧 Tam entegrasyon için yapman gerekenler

🔹 SQLite tablo yapısı (örnek):

CREATE TABLE visited_locations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    latitude REAL,
    longitude REAL,
    timestamp TEXT,
    radius INTEGER,
    country TEXT,
    city TEXT,
    district TEXT
);

🔹 Reverse geocode fonksiyonu (Swift):

func resolveLocationInfo(_ location: CLLocation, completion: @escaping (String?, String?, String?) -> Void) {
    let geocoder = CLGeocoder()
    geocoder.reverseGeocodeLocation(location) { placemarks, error in
        guard let placemark = placemarks?.first else {
            completion(nil, nil, nil)
            return
        }

        let country = placemark.country
        let city = placemark.administrativeArea
        let district = placemark.subAdministrativeArea

        completion(country, city, district)
    }
}


⸻

📌 Notlar
	•	İnternet yokken CLGeocoder yanıt vermeyebilir. Çözüm:
	•	nil dönerse boş kayıt yap → daha sonra bağlantı gelince güncelle.
	•	Her yeni CLLocation geldiğinde:
	1.	Daire çiz
	2.	SQLite’a ekle
	3.	CLGeocoder ile country, city, district bilgisi al
	4.	Eğer alınamazsa null bırak, sonra “catch-up” servisiyle tamamla

⸻

İşte en kritik teknik karar noktası:
“Her konumu birebir Point olarak mı kaydedelim, yoksa daha akıllı, optimize bir sistem mi kurmalıyız?”

⸻

🎯 Hedefin net:
	•	Harita üzerinde gerçekçi ve estetik şekilde gezilen alanları göstermek
	•	Ama bunu minimum veri + yüksek doğruluk + iyi performans ile yapmak

⸻

❌ Her GPS konumunu doğrudan kaydetmenin sorunları:

Sorun	Açıklama
📦 Veri şişmesi	Her 10 saniyede 1 kayıt, günlük 5 saat gezide ~1800 kayıt → 1 ayda >50.000 satır
🔋 Pil tüketimi	Sürekli veri yazmak CPU + IO yükü demek
🧠 Anlamsız tekrarlar	Aynı sokakta 5 adım ileride 5 kayıt = redundant veri
🗺️ Harita çizerken verimsizlik	1000 point > 5 daire = aşırı render yükü


⸻

✅ Optimize Yöntem: “Smart Visit Cluster” Sistemi

1. Küme mantığı:
	•	Konum verisi geldikçe son kaydedilen konuma bak:
	•	Eğer önceki noktanın radius’u içinde ise → kayıt alma
	•	Eğer yeni bölgeye geçilmişse → yeni kayıt oluştur

let minimumDistance = 100.0 // metre

if let lastLocation = previousLocation {
    let distance = location.distance(from: lastLocation)
    if distance > minimumDistance {
        // yeni bir nokta keşfedilmiş, kayıt et
    }
}


⸻

2. Daire + zaman birleşimi
	•	Aynı bölgede 30 dakika boyunca gezinmişse → sadece tek kayıt
	•	Kayıt: {latitude, longitude, radius, timestamp_start, timestamp_end}

⸻

3. Gelişmiş: GeoHash kullan
	•	Haritayı kare grid’lere ayır (örn. ~100m x 100m)
	•	Her GPS konumunu GeoHash’e çevir → sadece yeni bir GeoHash bölgesine girince kayıt al

// pseudo
if currentGeohash != lastGeohash {
    saveNewVisitedRegion()
}

📍 GeoHash: Her alanın coğrafi bir “string kod” ile temsil edilmesidir. Çok hızlı karşılaştırma yapılabilir.

⸻

🔄 Ne kaydetmelisin?

struct VisitedRegion {
    let latitude: Double
    let longitude: Double
    let radius: Int  // Örn: 150 metre
    let timestampStart: Date
    let timestampEnd: Date?
    let city: String?
    let district: String?
    let country: String?
    let geohash: String  // opsiyonel
}


⸻

🧠 Artıları:
	•	Aşırı veri yüklemezsin
	•	Render’da daire olarak göstermek kolay
	•	Her daire = anlamlı bir “ziyaret”
	•	Oyunlaştırma için “İstanbul’da 18 bölge gezilmiş” gibi veriler elde edersin

⸻

✨ Bonus: Dağınık “point” yerine sadeleşmiş “gezi alanı”
	•	Haritada çok daha estetik görünür
	•	Heatmap/daire render performansı uçurur
	•	Kullanıcıyı yormaz, veriyi anlamlandırır

⸻

🔚 Özet: En iyi yol

✅ GeoHash + Distance + Time birleşimi ile
“Ziyaret bölgesi” kavramı üzerinden kayıt al.
Her konum değil, her anlamlı keşif birimi kayıt edilsin.

Çok net konuşayım:
Evet, bu yöntem uzun vadede hem veri hem harita performansı açısından en sağlıklı sistemdir.
Nedenlerini hem teknik hem kullanıcı deneyimi açısından açıklıyorum:

⸻

🔥 Neden “Visited Region” mantığı en performanslı çözüm?

✅ 1. Veri boyutu kontrollü büyür
	•	Her 10 saniyede 1 point kaydetmek → yılda yüzbinlerce kayıt
	•	Bizim sistemde ise:
	•	Günde ~30–100 anlamlı “ziyaret bölgesi” kaydedilir
	•	1 yılda ≈ 30.000 point yerine ≈ 2.000-3.000 region
	•	Render edilirken sadece bu bölge merkezleri ve radius’ları çizilir
🧠 10x daha az veri + daha fazla anlam

⸻

✅ 2. Harita performansı mükemmel
	•	MapKit veya Mapbox fark etmez, haritada:
	•	10.000 MKPointAnnotation → performans çöküşü
	•	500 MKCircle → akıcı zoom/scroll

Zoom-in/zoom-out sırasında:
	•	MapView her daireyi otomatik scale eder
	•	GeoJSON olarak da export edilebilir
	•	Her daire zaten tek bir render objesi = GPU dostu

⸻

✅ 3. Heatmap / Bölge istatistiği üretimi kolay
	•	Daireler şehir/ilçe/ülkeye göre gruplanabilir
	•	Bir harita katmanında “Türkiye’de 28 bölge keşfedilmiş” efekti yaratılır
	•	Zoom seviyesine göre filtreleme (cluster) yapılabilir

⸻

📌 Teknik olarak nasıl desteklenir?
	•	SQLite: latitude, longitude, radius ile sorgulamak çok hafif
	•	Zoom seviyesi düşükken → sadece büyük radius’lar göster
	•	Yakınlaştırıldıkça → detaylı VisitedRegion kayıtları göster

func loadRegions(for mapZoom: Double) -> [VisitedRegion] {
    if mapZoom < 6 {
        return db.loadOnlyMajorRegions() // örn: il düzeyinde
    } else {
        return db.loadDetailedRegions() // ilçe / mahalle
    }
}


⸻

🧠 UX açısından ne kazandırır?
	•	Kullanıcı haritayı her açtığında net ve estetik “gezilmiş bölgeler” görür
	•	Tıklanınca: “Bu bölgeyi 3 kez ziyaret ettin, en son 14 Mayıs 2025”
	•	Bayrak gibi, seviye gibi, rozet gibi kullanılabilir

⸻

⚠️ Alternatif yöntemler neden riskli?

Yöntem	Sorun
Her GPS point	Aşırı veri, performans çöküşü, anlamsızlık
Yol çizgisi (polyline)	Sürekli araç kullanan biri için uygunsuz, statik gezen biri için karmaşık
Heatmap	Estetik ama bölge detayını kaybettirir (oyunlaştırma zorlaşır)


⸻

🚀 Sonuç:

Bu “visited region” sistemi seni gelecekte 1 milyon kullanıcıya da taşıyabilir.
Hem veri büyümesini yönetir, hem UI’ı sade tutar, hem oyunlaştırmayı destekler.


Süper. Aşağıda Roqua’nın “visited region” sistemini adım adım uygulamak için tam teknik yol haritasını veriyorum. Bunu doğrudan bir AI ajana veya dev ekibe aktarabilirsin.

⸻

🗺️ Roqua – Visited Region Sistemi Uygulama Talimatı

⸻

🎯 Amaç

GPS’ten gelen verileri her seferinde kaydetmek yerine, kullanıcı anlamlı olarak yeni bir bölgeye girdiğinde bir VisitedRegion nesnesi oluşturulacak. Bu nesneler:
	•	Haritada dairesel olarak gösterilecek
	•	SQLite’da saklanacak
	•	İleride oyunlaştırma ve istatistik için kullanılacak

⸻

🧱 1. Veri Modeli

🔹 VisitedRegion yapısı:

struct VisitedRegion {
    let id: Int?                 // Auto-incremented ID
    let latitude: Double         // Bölgenin merkezi
    let longitude: Double
    let radius: Int              // Varsayılan: 150 metre
    let timestampStart: Date
    let timestampEnd: Date?      // Ziyaret devam ediyorsa null
    let city: String?
    let district: String?
    let country: String?
    let geohash: String?         // 7-8 karakter hassasiyet
}


⸻

🗃️ 2. SQLite Tabloları

🔸 visited_regions tablosu:

CREATE TABLE visited_regions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    radius INTEGER NOT NULL,
    timestamp_start TEXT NOT NULL,
    timestamp_end TEXT,
    city TEXT,
    district TEXT,
    country TEXT,
    geohash TEXT
);


⸻

🧠 3. Kayıt Mantığı (VisitedRegionManager.swift)

🔹 Akış:
	1.	Yeni konum (CLLocation) geldiğinde:
	•	Son kaydedilen bölgeyi al (lastRegion)
	•	Eğer bu bölgenin radius’u içindeyse → kayıt alma
	•	Eğer dışındaysa → yeni VisitedRegion oluştur

🔹 Kod Mantığı:

func shouldCreateNewRegion(currentLocation: CLLocation, lastRegion: VisitedRegion?) -> Bool {
    guard let last = lastRegion else { return true }

    let lastCenter = CLLocation(latitude: last.latitude, longitude: last.longitude)
    let distance = currentLocation.distance(from: lastCenter)

    return distance > Double(last.radius)
}


⸻

🌍 4. Reverse Geocoding (CoreLocation)

🔹 Uygulama içinde:

let geocoder = CLGeocoder()
geocoder.reverseGeocodeLocation(currentLocation) { placemarks, error in
    if let placemark = placemarks?.first {
        let city = placemark.administrativeArea
        let district = placemark.subAdministrativeArea
        let country = placemark.country
        // region objesine yaz
    }
}

	•	Eğer geocoder başarısızsa: nil bırak
	•	İnternet geldiğinde null alanlar için geocode retry yapılabilir

⸻

🧪 5. GeoHash (Opsiyonel ama önerilir)

🔹 Swift’te GeoHash örnek kütüphesi:
	•	github.com/mrKlar/geohash

let geohash = Geohash.encode(latitude: lat, longitude: lng, precision: 7)

	•	Aynı geohash → aynı gridteyiz → kayıt alma

⸻

🗺️ 6. Haritada Gösterim (MapKit)

🔹 Daire çizme:

let circle = MKCircle(center: CLLocationCoordinate2D(latitude: region.latitude,
                                                      longitude: region.longitude),
                      radius: CLLocationDistance(region.radius))
mapView.addOverlay(circle)

🔹 Overlay Renderer:

func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let circle = overlay as? MKCircle {
        let renderer = MKCircleRenderer(circle: circle)
        renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.3)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 1
        return renderer
    }
    return MKOverlayRenderer()
}


⸻

🔄 7. Zoom Seviyesine Göre Süzme (Opsiyonel)

func loadRegions(for zoomLevel: Double) -> [VisitedRegion] {
    if zoomLevel < 6 {
        return db.loadMajorRegions() // Büyük şehir merkezleri
    } else {
        return db.loadAllRegions()
    }
}


⸻

🏆 8. Oyunlaştırma ile Kullanımı

Bu sistemden gelen city ve district alanları ile şu yapılabilir:

	•	“İstanbul’da 17 ilçe gezildi” → ilerleme çubuğu
	•	Tüm ilçeler gezilirse → Fatih Madalyonu
	•	SQLite’da bir region_stats tablosu tutularak bu analizler yapılır

⸻

📦 Bonus: CoreData ile de yapılabilir mi?

Evet, ama SQLite + Codable model daha sade ve kontrol sende olur. Tavsiye: SQLite.

⸻

✅ Sonuç

Bu sistem:
	•	Yüksek performanslı
	•	Düşük veri maliyetli
	•	Görsel olarak estetik
	•	Oyunlaştırmaya çok uygun
	•	iOS-native her özelliği kullanıyor

⸻

Örnek VisitedRegion.swift:

```
import Foundation
import CoreLocation

struct VisitedRegion: Identifiable, Codable {
    var id: Int64?                // SQLite auto-increment ID
    var latitude: Double          // Merkez koordinat
    var longitude: Double
    var radius: Int               // Varsayılan: 150 metre
    var timestampStart: Date      // Bölgeye ilk girilen zaman
    var timestampEnd: Date?       // İsteğe bağlı: bölgeden çıkış zamanı

    var city: String?             // Reverse geocoding ile alınır
    var district: String?
    var country: String?
    
    var geohash: String?          // 7-8 karakter, opsiyonel
}

// Yardımcı genişletmeler
extension VisitedRegion {
    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distance(to other: CLLocation) -> CLLocationDistance {
        let regionCenter = CLLocation(latitude: latitude, longitude: longitude)
        return regionCenter.distance(from: other)
    }

    func contains(location: CLLocation) -> Bool {
        return distance(to: location) <= Double(radius)
    }
}
```

Örnek VisitedRegionManager.swift
```
import Foundation
import CoreLocation

class VisitedRegionManager {
    static let shared = VisitedRegionManager()
    
    private var lastRegion: VisitedRegion?
    private let minDistanceThreshold: CLLocationDistance = 150 // metre
    private let defaultRadius: Int = 150

    private init() {}

    // Her yeni konum geldiğinde çağırılacak ana fonksiyon
    func handleNewLocation(_ location: CLLocation) {
        // 1. Bu lokasyon daha önce kaydedilen bölgeye yakın mı?
        if let last = lastRegion, last.contains(location: location) {
            // Aynı bölgedeyiz → yeni kayıt gerekmez
            return
        }

        // 2. Yeni bölge → region nesnesi oluştur
        let newRegion = VisitedRegion(
            id: nil,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: defaultRadius,
            timestampStart: Date(),
            timestampEnd: nil,
            city: nil,
            district: nil,
            country: nil,
            geohash: GeoHashHelper.encode(lat: location.coordinate.latitude,
                                           lon: location.coordinate.longitude,
                                           precision: 7)
        )

        // 3. Reverse geocoding başlat
        ReverseGeocoder.resolve(location: location) { enrichedRegion in
            // 4. SQLite’a kaydet
            SQLiteManager.shared.insertVisitedRegion(enrichedRegion)

            // 5. Son region’u güncelle
            self.lastRegion = enrichedRegion
        }
    }

    // Uygulama ilk açıldığında son kaydı getir
    func loadLastVisitedRegion() {
        lastRegion = SQLiteManager.shared.fetchLastVisitedRegion()
    }
}
```