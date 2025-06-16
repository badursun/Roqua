# 🏆 Roqua Achievement System - Hazırlama Tablosu ve Dokümantasyon

## 📋 **İçindekiler**
1. [Achievement Objesi Yapısı](#achievement-objesi-yapısı)
2. [Parametre Detayları](#parametre-detayları)
3. [Calculator Tipleri](#calculator-tipleri)
4. [Hazırlama Tablosu](#hazırlama-tablosu)
5. [Örnekler](#örnekler)
6. [Validation Kuralları](#validation-kuralları)

---

## 🎯 **Achievement Objesi Yapısı**

### **Temel JSON Schema**
```json
{
  "id": "string",                     // ✅ ZORUNLU: Benzersiz tanımlayıcı
  "category": "string",               // ✅ ZORUNLU: Kategori (camelCase)
  "type": "string",                   // ✅ ZORUNLU: Tip tanımı
  "title": "string",                  // ✅ ZORUNLU: Görünen başlık
  "description": "string",            // ✅ ZORUNLU: Açıklama metni
  "iconName": "string",               // ✅ ZORUNLU: SF Symbol adı
  "target": integer,                  // ✅ ZORUNLU: Hedef değer
  "isHidden": boolean,                // ✅ ZORUNLU: Gizli achievement flag
  "rarity": "string",                 // ✅ ZORUNLU: Nadir durumu
  "calculator": "string",             // ✅ ZORUNLU: Hesaplayıcı tipi
  "params": object|null               // ⚠️ KOŞULLU: Calculator'a bağlı parametreler
}
```

---

## 📊 **Parametre Detayları**

### **🔹 ID Parametresi**
- **Format**: `snake_case` önerilir
- **Kural**: Benzersiz olmalı, özel karakter yok
- **Örnekler**: `first_steps`, `istanbul_master`, `area_explorer_1km`

### **🔹 Category Parametresi**
**Mevcut Kategoriler** (camelCase format):
```javascript
const CATEGORIES = {
  "firstSteps": "İlk Adımlar",           // Başlangıç seviyesi
  "explorer": "Kaşif",                   // Keşif odaklı
  "adventurer": "Maceracı",              // İleri seviye keşif
  "worldTraveler": "Dünya Gezgini",      // Küresel keşif
  "cityMaster": "Şehir Ustası",          // Şehir bazlı
  "districtExplorer": "İlçe Kaşifi",     // İlçe bazlı
  "countryCollector": "Ülke Koleksiyoneri", // Ülke bazlı
  "areaExplorer": "Alan Kaşifi",         // Alan bazlı
  "percentageMilestone": "Yüzde Dönüm Noktaları", // Yüzdelik
  "dailyExplorer": "Günlük Kaşif",       // Günlük aktivite
  "weekendWarrior": "Hafta Sonu Savaşçısı" // Hafta sonu aktivite
}
```

### **🔹 Type Parametresi**
```javascript
const TYPES = {
  "milestone": "Kilometre Taşı",      // Sayısal hedefler
  "geographic": "Coğrafi",            // Coğrafi temelli
  "exploration": "Keşif",             // Keşif temelli
  "temporal": "Zamansal"              // Zaman temelli
}
```

### **🔹 Rarity Parametresi**
| Rarity | Türkçe | Zorluk | Point | Renk |
|--------|--------|---------|-------|------|
| `common` | Yaygın | ⭐ | 1 | Gümüş |
| `rare` | Nadir | ⭐⭐ | 3 | Altın |
| `epic` | Destansı | ⭐⭐⭐ | 5 | Mor |
| `legendary` | Efsanevi | ⭐⭐⭐⭐⭐ | 10 | Turuncu |

### **🔹 Target Parametresi**
- **Format**: Pozitif integer
- **Hesaplama**: Calculator'ın return değeriyle karşılaştırılır
- **Örnekler**: `10`, `100`, `1000000` (alan için)

---

## 🧮 **Calculator Tipleri**

### **1. 📊 MilestoneCalculator** 
```javascript
{
  "calculator": "milestone",
  "params": null,
  "description": "Toplam bölge sayısını sayar",
  "example_target": 100,
  "example_usage": "100 bölge keşfet"
}
```

### **2. 🏙️ CityCalculator**
```javascript
{
  "calculator": "city",
  "params": {
    "cityName": "İstanbul"    // String: Şehir adı
  },
  "description": "Belirli şehirdeki bölge sayısını sayar",
  "example_target": 50,
  "example_usage": "İstanbul'da 50 bölge keşfet"
}
```

### **3. 🗺️ DistrictCalculator**
```javascript
{
  "calculator": "district",
  "params": null,
  "description": "Benzersiz ilçe sayısını sayar",
  "example_target": 25,
  "example_usage": "25 farklı ilçe keşfet"
}
```

### **4. 🌍 CountryCalculator**
```javascript
{
  "calculator": "country",
  "params": null,
  "description": "Benzersiz ülke sayısını sayar",
  "example_target": 5,
  "example_usage": "5 farklı ülke ziyaret et"
}
```

### **5. 📐 AreaCalculator**
```javascript
{
  "calculator": "area",
  "params": {
    "unit": "square_meters"    // String: Alan birimi
  },
  "description": "Toplam keşfedilen alanı hesaplar (m²)",
  "example_target": 1000000,  // 1 km²
  "example_usage": "1 km² alan keşfet"
}
```

### **6. 📈 PercentageCalculator**
```javascript
{
  "calculator": "percentage",
  "params": {
    "multiplier": 1000         // Integer: Çarpan değeri
  },
  "description": "Dünya keşif yüzdesini hesaplar",
  "example_target": 1,         // %0.001 (1/1000)
  "example_usage": "Dünya'nın binde birini keşfet",
  "calculation": "percentage * multiplier"
}
```

### **7. 📅 DailyStreakCalculator**
```javascript
{
  "calculator": "daily_streak",
  "params": {
    "type": "consecutive_days" // String: Seri tipi
  },
  "description": "En uzun ardışık günlük keşif serisini hesaplar",
  "example_target": 7,
  "example_usage": "7 gün üst üste keşif yap"
}
```

### **8. 🌅 WeekendStreakCalculator**
```javascript
{
  "calculator": "weekend_streak",
  "params": {
    "type": "consecutive_weekends" // String: Hafta sonu tipi
  },
  "description": "En uzun ardışık hafta sonu keşif serisini hesaplar",
  "example_target": 4,
  "example_usage": "4 hafta sonu üst üste keşif yap"
}
```

---

## 📝 **Hazırlama Tablosu**

### **🎯 Temel Achievement Checklist**

| Alan | Kontrolü | Durum | Notlar |
|------|----------|-------|--------|
| **ID** | Benzersiz mi? | ☐ | snake_case kullan |
| **Title** | Anlaşılır mı? | ☐ | Kısa ve net olsun |
| **Description** | Açıklayıcı mı? | ☐ | Hedefi net belirt |
| **Category** | Doğru kategori? | ☐ | camelCase format |
| **Type** | Uygun tip? | ☐ | milestone/geographic/exploration/temporal |
| **Rarity** | Zorluğa uygun? | ☐ | common/rare/epic/legendary |
| **Icon** | SF Symbol geçerli? | ☐ | iOS'ta mevcut olmalı |
| **Target** | Makul hedef? | ☐ | Çok kolay/zor olmasın |
| **Calculator** | Doğru calculator? | ☐ | Hedefle uyumlu olsun |
| **Params** | Calculator parametreleri? | ☐ | Gerekiyorsa ekle |

### **🧪 Test Checklist**

| Test Alanı | Durum | Açıklama |
|------------|-------|----------|
| **JSON Syntax** | ☐ | Valid JSON formatı |
| **Enum Match** | ☐ | Category enum'ında var mı? |
| **Calculator Exists** | ☐ | Factory'de tanımlı mı? |
| **Parameter Validation** | ☐ | Parametreler geçerli mi? |
| **Target Logic** | ☐ | Calculator output ile tutarlı mı? |
| **Icon Display** | ☐ | UI'da düzgün görünüyor mu? |
| **Progress Calculation** | ☐ | İlerleme doğru hesaplanıyor mu? |

---

## 💡 **Hazırlama Örnekleri**

### **📍 Basit Milestone Achievement**
```json
{
  "id": "explorer_500",
  "category": "explorer",
  "type": "milestone",
  "title": "Orta Düzey Kaşif",
  "description": "500 bölge keşfet",
  "iconName": "binoculars.fill",
  "target": 500,
  "isHidden": false,
  "rarity": "rare",
  "calculator": "milestone",
  "params": null
}
```

### **🏙️ Şehir Bazlı Achievement**
```json
{
  "id": "izmir_master",
  "category": "cityMaster",
  "type": "geographic", 
  "title": "İzmir Ustası",
  "description": "İzmir'de 25+ bölge keşfet",
  "iconName": "building.columns.fill",
  "target": 25,
  "isHidden": false,
  "rarity": "rare",
  "calculator": "city",
  "params": {
    "cityName": "İzmir"
  }
}
```

### **📈 Yüzdelik Achievement**
```json
{
  "id": "percentage_1",
  "category": "percentageMilestone",
  "type": "exploration",
  "title": "Dünya'nın On Binde Biri",
  "description": "Dünya'nın %0.01'ini keşfet",
  "iconName": "globe.central.south.asia.fill",
  "target": 10,
  "isHidden": false,
  "rarity": "legendary",
  "calculator": "percentage",
  "params": {
    "multiplier": 1000
  }
}
```

### **⏰ Zamansal Achievement**
```json
{
  "id": "morning_explorer",
  "category": "dailyExplorer",
  "type": "temporal",
  "title": "Sabah Kaşifi",
  "description": "10 gün üst üste sabah keşif yap",
  "iconName": "sunrise.fill",
  "target": 10,
  "isHidden": false,
  "rarity": "epic",
  "calculator": "daily_streak",
  "params": {
    "type": "consecutive_days"
  }
}
```

---

## ✅ **Validation Kuralları**

### **🔍 Zorunlu Alanlar Kontrolü**
```javascript
const requiredFields = ['id', 'category', 'type', 'title', 'description', 
                       'iconName', 'target', 'isHidden', 'rarity', 'calculator'];
```

### **🎯 Category Validation**
```javascript
const validCategories = ['firstSteps', 'explorer', 'adventurer', 'worldTraveler', 
                        'cityMaster', 'districtExplorer', 'countryCollector', 
                        'areaExplorer', 'percentageMilestone', 'dailyExplorer', 
                        'weekendWarrior'];
```

### **⚡ Calculator-Params Matrix**
| Calculator | Params Zorunlu? | Geçerli Params |
|------------|-----------------|----------------|
| `milestone` | ❌ Hayır | `null` |
| `city` | ✅ Evet | `{cityName: "string"}` veya `{cityNames: ["string1", "string2"]}` |
| `district` | ❌ Hayır | `null` |
| `country` | ❌ Hayır | `null` |
| `area` | ⚠️ Opsiyonel | `{unit: "square_meters"}` |
| `percentage` | ✅ Evet | `{multiplier: 1000}` |
| `daily_streak` | ⚠️ Opsiyonel | `{type: "consecutive_days"}` |
| `weekend_streak` | ⚠️ Opsiyonel | `{type: "consecutive_weekends"}` |

### **🎨 Icon Validation**
```javascript
// SF Symbols kategorileri
const iconCategories = {
  communication: ['phone', 'message', 'mail'],
  weather: ['sun.max', 'cloud', 'rain'],
  transport: ['car', 'airplane', 'train'],
  places: ['building', 'house', 'tent'],
  nature: ['tree', 'leaf', 'mountain'],
  symbols: ['star', 'heart', 'flag'],
  human: ['person', 'figure.walk', 'figure.run']
};
```

---

## 🚀 **Yeni Achievement Ekleme Süreci**

### **1️⃣ Planlama Aşaması**
- [ ] Hedef belirleme (ne başarmak istiyoruz?)
- [ ] Kategori seçimi (hangi gruba ait?)
- [ ] Zorluk seviyesi (hangi rarity?)
- [ ] Calculator seçimi (nasıl hesaplanacak?)

### **2️⃣ Tasarım Aşaması**
- [ ] Başlık yazma (kısa ve çekici)
- [ ] Açıklama yazma (net ve anlaşılır)
- [ ] Icon seçimi (temsil edici)
- [ ] Target belirleme (makul ve test edilebilir)

### **3️⃣ Uygulama Aşaması**
- [ ] JSON objesi oluşturma
- [ ] Syntax kontrolü
- [ ] Validation testleri
- [ ] UI testleri

### **4️⃣ Test Aşaması**
- [ ] Build test (kod çalışıyor mu?)
- [ ] Progress hesaplama test
- [ ] UI görünüm test
- [ ] Achievement unlock test

---

## 📋 **Hızlı Referans Tablosu**

### **Common Achievement Patterns**

| Pattern | Category | Calculator | Target Örnekleri |
|---------|----------|------------|------------------|
| **Milestone** | explorer | milestone | 10, 50, 100, 500, 1000 |
| **City Master** | cityMaster | city | 25, 50, 100 (şehir başına) |
| **Area Explorer** | areaExplorer | area | 1000000 (1km²), 10000000 (10km²) |
| **Country Collector** | countryCollector | country | 3, 5, 10, 20 |
| **Daily Streak** | dailyExplorer | daily_streak | 3, 7, 14, 30 |
| **Percentage** | percentageMilestone | percentage | 1, 10, 100 (multiplier 1000) |

### **Rarity Distribution Önerileri**

| Kategori | Common | Rare | Epic | Legendary |
|----------|--------|------|------|-----------|
| **firstSteps** | 70% | 30% | 0% | 0% |
| **explorer** | 50% | 40% | 10% | 0% |
| **cityMaster** | 30% | 50% | 20% | 0% |
| **countryCollector** | 0% | 30% | 50% | 20% |
| **percentageMilestone** | 0% | 0% | 50% | 50% |

---

## 🔧 **Troubleshooting**

### **Sık Karşılaşılan Problemler**

| Problem | Neden | Çözüm |
|---------|-------|-------|
| Achievement görünmüyor | Category enum match yok | rawValue kontrol et |
| Progress hesaplanmıyor | Calculator bulunamıyor | Factory'de tanımlı mı? |
| Params çalışmıyor | JSON syntax hatası | Validation yap |
| Icon görünmüyor | SF Symbol mevcut değil | iOS'ta var mı kontrol et |
| Target ulaşılamıyor | Çok yüksek hedef | Makul değer koy |

---

---

## 🌍 **Şehir İsmi Standardizasyonu ve Çoklu Şehir Desteği**

### **🔍 Problem Analizi**

**Reverse Geocoding Inconsistency:**
- iOS CLGeocoder: "İstanbul" (Türkçe yerel isim)
- GPS Data: "Istanbul" (İngilizce standart)  
- Map Services: "İstanbul Province" (İngilizce + suffix)
- Different Locales: "Estambul" (İspanyolca)

### **✅ CityCalculator Çözümü**

**Otomatik Normalizasyon:**
```swift
private func normalizeCity(_ city: String) -> String {
    return city
        .lowercased()                              // Case-insensitive
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "ı", with: "i")  // Türkçe → İngilizce
        .replacingOccurrences(of: "ğ", with: "g")
        .replacingOccurrences(of: "ü", with: "u")
        .replacingOccurrences(of: "ş", with: "s")
        .replacingOccurrences(of: "ö", with: "o")
        .replacingOccurrences(of: "ç", with: "c")
        .replacingOccurrences(of: " province", with: "")  // Suffix temizleme
        .replacingOccurrences(of: " ili", with: "")
        .replacingOccurrences(of: " city", with: "")
}
```

**Matching Logic:**
1. **Exact Match**: "istanbul" = "istanbul" ✅
2. **Contains Match**: "İstanbul Province" contains "istanbul" ✅  
3. **Reverse Contains**: "istanbul" contains "ist" ✅

### **🔧 Çoklu Şehir Desteği**

**Eski Format (Tek şehir):**
```json
{
  "parameters": {
    "cityName": "istanbul"
  }
}
```

**Yeni Format (Çoklu şehir):**
```json
{
  "parameters": {
    "cityNames": ["istanbul", "ankara", "izmir"]
  }
}
```

**Backward Compatibility:** Eski format hala destekleniyor!

### **📋 Şehir İsmi Kuralları**

| Kural | Açıklama | Örnek |
|-------|----------|-------|
| **Lowercase** | Tüm şehir isimleri küçük harf | "istanbul", "ankara" |
| **Türkçe Karakter Yok** | ASCII normalize | "izmır" → "izmir" |
| **Suffix Yok** | Province, ili vb. eklenmez | "istanbul" ✅, "istanbul ili" ❌ |
| **Orijinal İsim** | Yerel dilde yazılmış isim tercih | "istanbul" ✅, "constantinople" ❌ |

### **🧪 Test Senaryoları**

| Region City | Target City | Match? | Sebep |
|------------|-------------|--------|-------|
| "İstanbul" | "istanbul" | ✅ | Normalization + exact match |
| "Istanbul Province" | "istanbul" | ✅ | Contains match |
| "ANKARA" | "ankara" | ✅ | Case normalization |
| "İzmır" | "izmir" | ✅ | Türkçe karakter dönüşümü |
| "Antalya" | "istanbul" | ❌ | Farklı şehir |

---

**💡 Bu dokümantasyon Roqua Achievement System v1.0 için hazırlanmıştır.** 