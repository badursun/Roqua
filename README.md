 # 🗺️ Roqua - Gizlilik Dostu Keşif Uygulaması

<div align="center">

![iOS 18.5+](https://img.shields.io/badge/iOS-18.5%2B-blue)
![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blue)
![Privacy First](https://img.shields.io/badge/Privacy-First-green)
![Offline](https://img.shields.io/badge/Mode-Offline-purple)

**Dünyayı keşfet, gizliliğini koru.**

*Gezdiğin yerleri haritada görselleştir, hiçbir veri paylaşmadan.*

</div>

---

## 📖 **Roqua Nedir?**

**Roqua**, gerçek hayatta gezdiğin yerleri "fog of war" sistemiyle haritada görselleştiren, **tamamen offline** çalışan iOS uygulamasıdır. Uygulamayı kapatsan bile arka planda konum takibi yaparak, sadece senin cihazında saklanan verilerle keşif yolculuğunu haritalar.

### 🎯 **Temel Felsefe**
- **🔒 %100 Gizlilik:** Verileriniz sadece cihazınızda, hiçbir sunucuya gönderilmez
- **🌐 Tamamen Offline:** İnternet bağlantısı gerektirmez
- **🎮 Gamification:** Dinamik achievement sistemi ile keşif motivasyonu
- **📊 İstatistikler:** Dünyanın yüzde kaçını keşfettiğinizi görün

---

## ✨ **Özellikler**

### 🗺️ **Fog of War Harita Sistemi**
- **Karanlık Dünya:** Tüm harita başlangıçta karanlık görünür
- **Keşif Aydınlatması:** Gittiğin yerler dairesel olarak aydınlanır (100m-200m radius)
- **Gerçek Zamanlı:** Hareket ederken harita anında güncellenir
- **Akıllı Birleştirme:** Yakın alanlar otomatik olarak birleşir

### 🏆 **Dinamik Achievement Sistemi**
- **70+ Farklı Başarım:** Milestone, Şehir, İlçe, Ülke, Alan temelli
- **JSON-Driven Yapı:** Yeni achievement'lar kod değişikliği olmadan eklenir
- **8 Calculator Türü:** Milestone, City, District, Country, Area, Percentage, DailyStreak, WeekendStreak
- **4 Nadir Seviyesi:** Common, Rare, Epic, Legendary
- **Gizli Achievement'lar:** Keşfedilmesi gereken sürpriz ödüller
- **Custom Image Desteği:** SF Symbol veya özel resim kullanımı

### 📊 **Gelişmiş İstatistikler**
- **Dünya Keşif Yüzdesi:** Hassas grid-based hesaplama (5 decimal)
- **Şehir/İlçe/Ülke Analizi:** Detaylı coğrafi breakdown
- **Streak Sistemi:** Günlük keşif zincirleri
- **Progress Tracking:** Her achievement için ilerleme takibi
- **Circular Progress Rings:** Görsel ilerleme gösterimi

### ⚙️ **Gelişmiş Ayarlar**
- **Keşif Parametreleri:** Radius, hassasiyet, clustering ayarları
- **Harita Kişiselleştirme:** Map türü, görünüm, şeffaflık
- **Background Processing:** Arka plan çalışma kontrolü
- **Export/Import:** Veri yedekleme ve geri yükleme

---

## 🏗️ **Teknik Mimari**

### 📱 **Platform & Teknolojiler**
```
• iOS 18.5+ (iPhone Only)
• Swift 5.0 + SwiftUI
• MapKit Framework
• Core Location (Always Authorization)
• SQLite (Persistent Storage)
• Bundle ID: com.adjans.roqua.Roqua
```

### 🗄️ **Veri Mimarisi**
```swift
// Core Data Models
VisitedRegion {
    latitude: Double
    longitude: Double  
    timestamp: Date
    accuracy: Double
    city: String?        // Reverse geocoding
    district: String?    // Admin level
    country: String?     // Country info
}

Achievement {
    id: String
    category: AchievementCategory
    type: AchievementType
    title: String
    description: String
    iconName: String
    imageName: String?   // Custom image support
    target: Int
    rarity: AchievementRarity
}
```

### 🎮 **Dynamic Achievement Architecture**

#### **JSON-Driven Configuration**
```json
{
  "version": "1.0",
  "achievements": [
    {
      "id": "istanbul_master",
      "title": "İstanbul Ustası", 
      "category": "cityMaster",
      "calculator": "city",
      "target": 50,
      "rarity": "epic",
      "parameters": {
        "cityName": "İstanbul"
      }
    }
  ]
}
```

#### **Modular Calculator System**
```swift
protocol AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int
}

// 8 Built-in Calculators:
MilestoneCalculator    // Toplam bölge sayısı
CityCalculator        // Şehir-specific keşif
DistrictCalculator    // Unique ilçe sayısı  
CountryCalculator     // Unique ülke sayısı
AreaCalculator        // Toplam keşfedilen alan
PercentageCalculator  // Dünya yüzde oranı
DailyStreakCalculator // Günlük keşif zincirleri
WeekendStreakCalculator // Hafta sonu patterns
```

---

## 📂 **Proje Yapısı**

```
Roqua/
├── 📱 App Core
│   ├── RoquaApp.swift              # Ana app entry point
│   ├── ContentView.swift           # Ana container view
│   └── Info.plist                  # App permissions & config
│
├── 🗺️ Views/
│   ├── Components/                 # Reusable UI components
│   │   ├── AchievementIconView.swift      # SF Symbol + Custom Image
│   │   ├── CircularProgressRing.swift     # Progress animations  
│   │   ├── EnhancedStatCard.swift         # Statistics display
│   │   ├── AchievementNotificationView.swift # Achievement popups
│   │   └── CompactAchievementSummary.swift   # Dashboard summary
│   ├── MapView/                    # Harita görünümleri
│   ├── AchievementPageView.swift   # Achievement koleksiyonu
│   ├── OnboardingView.swift        # İlk kullanım rehberi
│   └── SettingsView.swift          # Ayarlar sayfası
│
├── 🎮 Managers/
│   ├── AchievementManager.swift    # Core achievement engine
│   ├── VisitedRegionManager.swift  # Location data management  
│   ├── GridHashManager.swift       # Exploration percentage calc
│   └── ReverseGeocodingManager.swift # Address enrichment
│
├── 🧮 Calculators/
│   ├── AchievementCalculator.swift # Protocol + Factory
│   ├── MilestoneCalculator.swift   # Basic milestone logic
│   ├── CityCalculator.swift        # City-based calculations
│   ├── DistrictCalculator.swift    # District counting
│   ├── CountryCalculator.swift     # Country exploration  
│   ├── AreaCalculator.swift        # Geographic area calc
│   ├── PercentageCalculator.swift  # World percentage
│   ├── DailyStreakCalculator.swift # Daily activity streaks
│   └── WeekendStreakCalculator.swift # Weekend patterns
│
├── 📋 Models/
│   ├── AchievementDefinition.swift # JSON achievement structure
│   ├── AppSettings.swift           # User preferences
│   └── LocationModel.swift         # Core location structures
│
├── 🎨 Assets.xcassets/
│   ├── AppIcon.appiconset/         # App icons
│   ├── AccentColor.colorset/       # App color scheme
│   └── custom_images.imageset/     # Achievement custom images
│
├── 📄 Resources/
│   └── achievements.json           # Dynamic achievement config
│
└── 🧪 Tests/
    ├── RoquaTests/                 # Unit tests
    └── RoquaUITests/               # UI automation tests
```

---

## 🚀 **Kurulum & Çalıştırma**

### **Gereksinimler**
- Xcode 16.4+
- iOS 18.5+ (Deployment Target)
- iPhone (iPad desteklenmez)
- macOS Sonoma+ (Development)

### **Local Development**
```bash
# Repository clone
git clone https://github.com/badursun/Roqua.git
cd Roqua

# Xcode'da aç
open Roqua.xcodeproj

# iPhone 16 Pro simulator'de build
⌘ + R (Run)
```

### **Production Build**
```bash
# Clean build
xcodebuild -project Roqua.xcodeproj -scheme Roqua clean

# Release build  
xcodebuild -project Roqua.xcodeproj -scheme Roqua \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Release build
```

---

## 🔒 **Gizlilik & Güvenlik**

### **Veri Toplama: YOK** ❌
- Kişisel bilgi talep etmez
- Hesap oluşturma gerektirmez  
- Analytics/tracking yoktur
- Reklam sistemi yoktur

### **Veri Saklama: %100 Local** ✅
- Tüm veriler cihazda SQLite'da
- iCloud sync opsiyonel (Premium)
- Manuel export/import mümkün
- Tamamen offline çalışır

### **Konum İzinleri**
```plist
NSLocationAlwaysAndWhenInUseUsageDescription:
"Roqua'nın arka planda çalışması, uygulamayı kapatsan bile 
gezdiğin yerleri kaydetmesini sağlar. Tüm veriler cihazında 
güvenle saklanır, hiçbir sunucuya gönderilmez."

NSLocationWhenInUseUsageDescription:  
"Roqua, gezdiğin yerleri haritada gösterebilmek için konumuna 
ihtiyaç duyar. Veriler sadece cihazında saklanır."
```

---

## 🎮 **Achievement Sistemi**

### **Kategori Türleri**
```swift
enum AchievementCategory {
    case firstSteps          // İlk Adımlar (10-100 bölge)
    case explorer           // Kaşif (100-1000)  
    case adventurer         // Maceracı (1000-10000)
    case cityMaster         // Şehir Ustası (city-specific)
    case districtExplorer   // İlçe Kaşifi (district counting)
    case countryCollector   // Ülke Koleksiyoncusu
    case percentageMilestone // Dünya Yüzde Dönüm Noktaları
}
```

### **Achievement Örnekleri**

#### **🏁 Milestone Achievements**
- **İlk Adımlar** - 10 bölge keşfet
- **Kaşif** - 100 bölge keşfet  
- **Maceracı** - 1,000 bölge keşfet
- **Dünya Gezgini** - 10,000 bölge keşfet

#### **🏙️ City Achievements**  
- **İstanbul Ustası** - İstanbul'da 50 bölge
- **Ankara Uzmanı** - Ankara'da 30 bölge
- **İzmir Kaşifi** - İzmir'de 25 bölge

#### **🌍 Geographic Achievements**
- **İlçe Kaşifi** - 10 farklı ilçe
- **Dünya Gezgini** - 5 farklı ülke  
- **Alan Ustası** - 10 km² keşfet
- **Dünya'nın Binde Biri** - 0.001% keşfet

#### **⏰ Temporal Achievements**
- **Günlük Kaşif** - 7 gün streak
- **Hafta Sonu Savaşçısı** - 4 hafta sonu streak

### **Yeni Achievement Ekleme**
```json
// achievements.json'a ekleme
{
  "id": "bursa_master",
  "title": "Bursa Uzmanı",
  "description": "Bursa'da 40 bölge keşfet",
  "category": "cityMaster", 
  "calculator": "city",
  "target": 40,
  "rarity": "rare",
  "iconName": "building.2.fill",
  "imageName": null,
  "parameters": {
    "cityName": "Bursa"
  }
}
```

---

## 📊 **Sistem Performansı**

### **Bellek & Storage**
- **Uygulama Boyutu:** ~15MB
- **SQLite Database:** ~5-50MB (kullanıma göre)
- **Memory Usage:** <120MB peak
- **Battery Impact:** <6%/hour (optimize edilmiş)

### **Coğrafi Hassasiyet**
- **GPS Accuracy:** 50m threshold (ayarlanabilir)
- **Grid Resolution:** ~111m x 111m (1/1000 degree)
- **Exploration Radius:** 100m (yürüyüş), 200m (araç)
- **Percentage Precision:** 5 decimal places

### **Achievement Performansı**
- **Calculation Time:** <100ms per update
- **JSON Loading:** <50ms app launch
- **UI Render:** <500ms achievement page
- **Background Update:** <30s processing window

---

## 🛠️ **Geliştirme Araçları**

### **Achievement Configurator**
```bash
# Web-based achievement management tool
cd AchievementConfigrator/
python -m http.server 8000
# http://localhost:8000 adresinde açılır
```

**Özellikler:**
- ✅ Visual achievement editor
- ✅ JSON import/export  
- ✅ Parameter validation
- ✅ SF Symbol picker
- ✅ Real-time preview

### **Test Scripts**
```bash
# Build verification
./clear_and_test.sh

# GPX route testing  
./test_gpx_route.sh
```

---

## 📈 **Roadmap & Gelecek Planları**

### **🎯 Phase 1: Core Enhancements (1 hafta)**
- [ ] Achievement unlock animations (confetti, haptic)
- [ ] Local notification system
- [ ] Background processing optimization
- [ ] Custom achievement images expansion

### **🎯 Phase 2: Premium Features (2 hafta)**  
- [ ] Subscription monetization model
- [ ] Advanced analytics dashboard
- [ ] Cloud sync (iCloud integration)
- [ ] Export capabilities (GPX, KML)

### **🎯 Phase 3: Social & Sharing (1 hafta)**
- [ ] Achievement sharing (privacy-safe)
- [ ] Screenshot generation system
- [ ] Personal statistics export
- [ ] Family sharing support

### **🎯 Phase 4: Advanced Features (Future)**
- [ ] Seasonal achievements
- [ ] Weather-based challenges  
- [ ] Machine learning suggestions
- [ ] Apple Watch companion app

---

## 🤝 **Katkı & Geliştirme**

### **Git Workflow**
```bash
# Feature branch oluştur
git checkout -b feature/yeni-ozellik

# Değişiklikleri commit et
git add .
git commit -m "feat: yeni özellik eklendi"

# Pull request aç
git push origin feature/yeni-ozellik
```

### **Code Standards**
- **Language:** Swift 5.0 + SwiftUI
- **Architecture:** Feature-based modular (MVVM)
- **Conventions:** Apple Human Interface Guidelines
- **Testing:** Unit tests + UI automation
- **Documentation:** Code comments (Turkish)

### **Build Requirements**
- Always build with **iPhone 16 Pro** target
- Test on multiple iOS versions (18.5+)
- Verify offline functionality
- Performance profiling mandatory

---

## 📄 **Lisans & İletişim**

### **Proje Bilgileri**
- **Geliştirici:** Anthony Burak DURSUN  
- **GitHub:** [github.com/badursun/Roqua](https://github.com/badursun/Roqua)
- **Bundle ID:** `com.adjans.roqua.Roqua`
- **Version:** 1.0 (App Store'a hazırlanıyor)

### **Destek & Feedback**
- 🐛 **Bug Reports:** GitHub Issues
- 💡 **Feature Requests:** GitHub Discussions  
- 📧 **Contact:** Issues kısmından iletişim kurabilirsiniz

---

<div align="center">

**🗺️ Dünyayı keşfet, gizliliğini koru. 🔒**

*Made with ❤️ in Turkey*

[![GitHub Stars](https://img.shields.io/github/stars/badursun/Roqua?style=social)](https://github.com/badursun/Roqua)
[![GitHub Issues](https://img.shields.io/github/issues/badursun/Roqua)](https://github.com/badursun/Roqua/issues)
[![GitHub License](https://img.shields.io/github/license/badursun/Roqua)](https://github.com/badursun/Roqua/blob/main/LICENSE)

</div>