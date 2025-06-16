# 🏗️ POI Achievement Development Guide

## 📋 Overview
Roqua uygulamasında artık herhangi bir POI (Point of Interest) türü için achievement sistemi geliştirebilirsiniz. Bu rehber, yeni POI achievement'ları nasıl ekleneceğini detaylı olarak açıklar.

## 🏛️ System Architecture

### Current POI Detection System
- **POIEnrichmentManager:** MapKit ile POI tespiti
- **Flexible Database Schema:** `poi_name`, `poi_category`, `poi_type` alanları
- **Category-Based Filtering:** String tabanlı esnek kategori sistemi
- **Achievement Calculators:** Çeşitli POI calculator'ları

### Supported Calculator Types
- `religious_visit` - Dini mekanlar (genel)
- `mosque_visit` - Camiler (özel)
- `church_visit` - Kiliseler (özel)
- `multi_religion` - Çoklu din ziyareti
- `poi` - Genel POI calculator (her türlü POI için)

## 🎯 How to Add New POI Achievements

### Step 1: Identify POI Categories
POI kategorileri MapKit tarafından döndürülen kategorilerdir:

```swift
// Yaygın POI Kategorileri:
"hospital"      // Hastaneler
"school"        // Okullar  
"university"    // Üniversiteler
"library"       // Kütüphaneler
"museum"        // Müzeler
"park"          // Parklar
"restaurant"    // Restoranlar
"cafe"          // Kafeler
"gas_station"   // Benzin istasyonları
"pharmacy"      // Eczaneler
"bank"          // Bankalar
"post_office"   // Postaneler
"police"        // Polis merkezleri
"fire_station"  // İtfaiye istasyonları
"cemetery"      // Mezarlıklar
"stadium"       // Stadyumlar
"theater"       // Tiyatrolar
"shopping_mall" // AVM'ler
"supermarket"   // Süpermarketler
```

### Step 2: Choose Achievement Category
Achievement kategori sistemini kullanın:

```json
"category": "poiExplorer"     // Genel POI keşfi
"category": "religiousVisitor" // Dini mekan ziyareti
"category": "healthcareVisitor" // Sağlık mekanları
"category": "educationExplorer" // Eğitim kurumları
"category": "cultureExplorer"   // Kültürel mekanlar
// Yeni kategori ekleyebilirsiniz
```

### Step 3: Add Achievement to JSON
`Roqua/achievements.json` dosyasına yeni achievement ekleyin:

```json
{
  "id": "unique_achievement_id",
  "title": "Achievement Başlığı",
  "description": "Achievement açıklaması",
  "iconName": "sf_symbol_name",
  "imageName": null,
  "rarity": "common/rare/epic/legendary",
  "isHidden": false,
  "category": "poiExplorer",
  "type": "geographic",
  "target": 5,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "hospital",
    "visitType": "count"
  }
}
```

## 📝 Achievement Examples by POI Type

### Healthcare POI Achievements
```json
{
  "id": "hospital_explorer",
  "title": "Hastane Gezgini",
  "description": "5 farklı hastane ziyaret et",
  "iconName": "cross.circle.fill",
  "rarity": "common",
  "category": "poiExplorer",
  "target": 5,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "hospital",
    "visitType": "count"
  }
},
{
  "id": "pharmacy_visitor",
  "title": "Eczane Ziyaretçisi",
  "description": "10 farklı eczane ziyaret et",
  "iconName": "pills.fill",
  "rarity": "rare",
  "category": "poiExplorer",
  "target": 10,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "pharmacy",
    "visitType": "count"
  }
}
```

### Education POI Achievements
```json
{
  "id": "university_explorer",
  "title": "Üniversite Gezgini",
  "description": "3 farklı üniversite ziyaret et",
  "iconName": "graduationcap.fill",
  "rarity": "rare",
  "category": "poiExplorer",
  "target": 3,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "university",
    "visitType": "count"
  }
},
{
  "id": "library_lover",
  "title": "Kütüphane Sevdalısı",
  "description": "7 farklı kütüphane ziyaret et",
  "iconName": "books.vertical.fill",
  "rarity": "epic",
  "category": "poiExplorer",
  "target": 7,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "library",
    "visitType": "count"
  }
}
```

### Culture & Entertainment POI Achievements
```json
{
  "id": "museum_enthusiast",
  "title": "Müze Tutkunu",
  "description": "10 farklı müze ziyaret et",
  "iconName": "building.columns.fill",
  "rarity": "epic",
  "category": "poiExplorer",
  "target": 10,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "museum",
    "visitType": "count"
  }
},
{
  "id": "theater_fan",
  "title": "Tiyatro Hayranı",
  "description": "5 farklı tiyatro ziyaret et",
  "iconName": "theatermasks.fill",
  "rarity": "rare",
  "category": "poiExplorer",
  "target": 5,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "theater",
    "visitType": "count"
  }
}
```

### Sports POI Achievements
```json
{
  "id": "stadium_visitor",
  "title": "Stadyum Ziyaretçisi",
  "description": "3 farklı stadyum ziyaret et",
  "iconName": "sportscourt.fill",
  "rarity": "rare",
  "category": "poiExplorer",
  "target": 3,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "stadium",
    "visitType": "count"
  }
}
```

### Shopping POI Achievements
```json
{
  "id": "shopping_explorer",
  "title": "Alışveriş Gezgini",
  "description": "15 farklı AVM ziyaret et",
  "iconName": "bag.fill",
  "rarity": "epic",
  "category": "poiExplorer",
  "target": 15,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "shopping_mall",
    "visitType": "count"
  }
}
```

### Food & Dining POI Achievements
```json
{
  "id": "restaurant_explorer",
  "title": "Restoran Gezgini",
  "description": "25 farklı restoran ziyaret et",
  "iconName": "fork.knife",
  "rarity": "common",
  "category": "poiExplorer",
  "target": 25,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "restaurant",
    "visitType": "count"
  }
},
{
  "id": "cafe_lover",
  "title": "Kafe Sevdalısı",
  "description": "20 farklı kafe ziyaret et",
  "iconName": "cup.and.saucer.fill",
  "rarity": "common",
  "category": "poiExplorer",
  "target": 20,
  "calculator": "poi",
  "parameters": {
    "poiCategory": "cafe",
    "visitType": "count"
  }
}
```

## 🛠️ Advanced Parameters

### Visit Types
```json
"visitType": "count"    // Benzersiz POI sayısı (default)
"visitType": "total"    // Toplam ziyaret sayısı
"visitType": "unique"   // Benzersiz POI (count ile aynı)
```

### City Filtering
```json
"parameters": {
  "poiCategory": "museum",
  "visitType": "count",
  "cityName": "istanbul"  // Sadece İstanbul'daki müzeler
}
```

### Multiple Categories
```json
"parameters": {
  "poiCategories": ["restaurant", "cafe"], // Birden fazla kategori
  "visitType": "count"
}
```

## 🏆 Achievement Category Management

### Adding New Categories
1. `AchievementCategory` enum'una yeni kategori ekleyin
2. `AchievementPageView.swift`'te kategori başlığını tanımlayın
3. Uygun ikon seçin

```swift
// AchievementCategory enum
case healthcareExplorer = "healthcareExplorer"
case cultureExplorer = "cultureExplorer"
case sportsExplorer = "sportsExplorer"

// AchievementPageView.swift
case .healthcareExplorer:
    return ("Sağlık Gezgini", "cross.circle.fill")
case .cultureExplorer:
    return ("Kültür Gezgini", "building.columns.fill")
case .sportsExplorer:
    return ("Spor Gezgini", "sportscourt.fill")
```

## 🔍 Testing New POI Achievements

### 1. Simülatörde Test
- Yeni achievement'ları `achievements.json`'a ekleyin
- App'i build edin ve çalıştırın
- Achievement page'de yeni achievement'ları kontrol edin

### 2. Database Test
```sql
-- Simulated POI visit insert
INSERT INTO visited_regions 
(latitude, longitude, radius, timestamp_start, visit_count, 
 poi_name, poi_category, poi_type)
VALUES 
(41.0082, 28.9784, 200, '2025-06-16T20:00:00Z', 1,
 'Test Hospital', 'hospital', 'medical');
```

### 3. Achievement Progress Test
- Achievement manager'ın progress hesaplamasını kontrol edin
- Category filtering'in doğru çalıştığını doğrulayın

## 🚀 Best Practices

### Achievement Design
1. **Clear Descriptions:** Net ve anlaşılır açıklamalar yazın
2. **Appropriate Targets:** Makul hedefler belirleyin (3-25 arası)
3. **Rarity Balance:** Common'dan Legendary'ye doğru zorluk artırın
4. **Icon Selection:** POI türüne uygun SF Symbol seçin

### Performance Considerations
1. **Category Grouping:** Benzer POI'ları aynı kategoride toplayın
2. **Index Usage:** Veritabanı sorguları için index'leri kullanın
3. **Caching:** POI enrichment sonuçlarını cache'leyin

### Localization
1. **Turkish Content:** Başlık ve açıklamaları Türkçe yazın
2. **Cultural Context:** Türkiye'ye uygun POI türlerini tercih edin

## 📈 Future Enhancements

### Possible Extensions
- **Distance-based achievements:** Belirli mesafedeki POI'lar
- **Time-based achievements:** Belirli zaman diliminde ziyaret
- **Combo achievements:** Farklı POI türlerinin kombinasyonu
- **Frequency achievements:** Aynı POI'ya düzenli ziyaret
- **Regional achievements:** Bölgesel POI keşfi

### Advanced Features
- **POI Quality Rating:** Popular/trending POI'lar için bonus
- **Social Integration:** Arkadaşlarla POI keşfi yarışması
- **Seasonal POI:** Mevsimlik POI achievement'ları

---

## 🎯 Quick Start Checklist

- [ ] POI kategorisini belirle (hospital, museum, etc.)
- [ ] Achievement kategorisini seç (poiExplorer, etc.)
- [ ] JSON'da achievement tanımla
- [ ] Uygun ikon seç
- [ ] Target ve rarity belirle
- [ ] Parameters'ı yapılandır
- [ ] Test et ve doğrula

Bu rehberle artık kolayca yeni POI achievement'ları ekleyebilirsiniz! 🚀 