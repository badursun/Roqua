# 🏆 Roqua Achievement Configurator

Modern ve kullanıcı dostu Roqua Achievement System configurator'u. JSON tabanlı başarım yönetimi için web arayüzü.

## ✨ Özellikler

### 📊 **Başarım Yönetimi**
- ✅ JSON dosyadan başarım içe aktarma
- ✅ Başarım ekleme, düzenleme, silme
- ✅ Real-time filtreleme ve arama
- ✅ Kategori bazlı gruplama
- ✅ Grid ve liste görünüm seçenekleri

### 🎯 **Calculator Desteği**
- **Milestone**: Toplam bölge sayısı
- **City**: Şehir bazlı bölge sayısı  
- **District**: Unique ilçe sayısı
- **Country**: Unique ülke sayısı
- **Area**: Toplam alan hesaplama
- **Percentage**: Dünya keşif yüzdesi
- **Daily Streak**: Günlük seri
- **Weekend Streak**: Hafta sonu serisi
- **Multi City**: Çoklu şehir toplamı
- **Time Range**: Zaman dilimi filtreleme
- **Conditional**: Koşullu hesaplamalar

### 🎨 **Modern UI**
- Responsive tasarım
- Apple HIG inspired interface
- Smooth animasyonlar
- Toast bildirimler
- Keyboard shortcuts

## 🚀 Kullanım

### **Başlangıç**
1. `index.html` dosyasını tarayıcıda açın
2. Örnek başarımlar otomatik yüklenir
3. JSON dosyası içe aktararak başlayabilirsiniz

### **Keyboard Shortcuts**
- `Ctrl/⌘ + N`: Yeni başarım
- `Ctrl/⌘ + S`: JSON dışa aktarma  
- `Ctrl/⌘ + O`: JSON içe aktarma
- `Esc`: Modal'ları kapat

### **JSON Formatı**
```json
{
  "version": "1.0",
  "lastUpdated": "2024-01-01T00:00:00Z",
  "achievements": [
    {
      "id": "unique_id",
      "category": "categoryName",
      "type": "geographic|milestone|exploration|temporal",
      "title": "Başarım Adı",
      "description": "Açıklama",
      "iconName": "🏆",
      "target": 100,
      "isHidden": false,
      "rarity": "common|rare|epic|legendary",
      "calculator": "milestone|city|district|...",
      "params": {
        "cityName": "İstanbul"
      }
    }
  ]
}
```

## 📁 Dosya Yapısı

```
AchievementConfigrator/
├── index.html              # Ana HTML dosyası
├── styles.css              # CSS stilleri
├── achievement-manager.js  # Achievement yönetim sınıfı
├── app.js                  # Ana uygulama kontrolü
├── sample-achievements.json # Örnek JSON dosyası
└── README.md               # Bu dosya
```

## 🛠️ Teknik Detaylar

### **Modüler Yapı**
- `AchievementManager`: CRUD işlemleri, filtreleme
- `App`: UI kontrolleri, modal yönetimi
- Bağımsız CSS component'ları

### **Performans**
- Efficient DOM manipulation
- Debounced search
- Minimal re-renders
- CSS animations (60fps)

### **Validation**
- ID uniqueness kontrolü
- Required field validation
- JSON format validation
- Target value validation

## 🎯 Calculator Örnekleri

### **City Calculator**
```json
{
  "calculator": "city",
  "params": {
    "cityName": "İstanbul"
  }
}
```

### **Multi City Calculator**
```json
{
  "calculator": "multi_city",
  "params": {
    "cities": ["İzmir", "Muğla", "Aydın"],
    "operation": "sum"
  }
}
```

### **Time Range Calculator**
```json
{
  "calculator": "time_range",
  "params": {
    "start_time": "23:00",
    "end_time": "05:00",
    "timezone": "local"
  }
}
```

### **Conditional Calculator**
```json
{
  "calculator": "conditional",
  "params": {
    "conditions": [
      {
        "type": "city_filter",
        "value": "İstanbul"
      },
      {
        "type": "unique_districts",
        "minimum": 20
      }
    ],
    "operation": "and"
  }
}
```

## 📋 Desteklenen Parametreler

| Calculator | Parametreler | Açıklama |
|------------|--------------|----------|
| `milestone` | - | Sadece target değeri |
| `city` | `cityName` | Şehir adı |
| `district` | - | Unique ilçeler |
| `country` | - | Unique ülkeler |
| `area` | `unit` | Alan birimi |
| `percentage` | `multiplier` | Çarpan değeri |
| `daily_streak` | `type` | Seri türü |
| `weekend_streak` | `type` | Hafta sonu türü |
| `multi_city` | `cities`, `operation` | Şehir listesi ve işlem |
| `time_range` | `start_time`, `end_time` | Zaman aralığı |
| `conditional` | `conditions`, `operation` | Koşul listesi |

## 🔄 Swift Entegrasyonu

Bu configurator ile oluşturulan JSON dosyası doğrudan Swift Achievement Manager'da kullanılabilir:

```swift
// JSON'dan achievements yükle
func loadAchievements() {
    guard let url = Bundle.main.url(forResource: "achievements", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let definitions = try? JSONDecoder().decode([AchievementDefinition].self, from: data) else {
        return
    }
    
    achievementDefinitions = definitions
    achievements = definitions.map { convertToAchievement($0) }
}
```

## 🎨 Customization

### **CSS Variables**
```css
:root {
    --primary-color: #007AFF;
    --success-color: #34C759;
    --warning-color: #FF9500;
    --danger-color: #FF3B30;
    /* ... */
}
```

### **Icon Mapping**
Emoji iconları kullanın veya custom mapping ekleyin:
```javascript
const iconMap = {
    'figure.walk': '🚶',
    'building.2.fill': '🏢',
    'map.circle.fill': '🗺️'
    // ...
};
```

## 📊 Export Format

Dışa aktarılan JSON Roqua dinamik achievement sistemi ile tam uyumlu:

- ✅ Version bilgisi
- ✅ Timestamp
- ✅ Validation metadata
- ✅ Calculator parametreleri
- ✅ Progressive enhancement ready

## 🚀 Deployment

Static dosyalar olduğu için herhangi bir web server'da çalışır:

```bash
# Simple HTTP server
python -m http.server 8000

# Node.js
npx serve .

# Nginx/Apache static hosting
```

## 📈 Roadmap

- [ ] Bulk operations
- [ ] Achievement templates
- [ ] Visual icon picker
- [ ] Calculator preview
- [ ] Real-time validation
- [ ] Collaborative editing
- [ ] Git integration

---

**🏆 Roqua Achievement Configurator** - Dinamik başarım sistemi için modern web arayüzü. 