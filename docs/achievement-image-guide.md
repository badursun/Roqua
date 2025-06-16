# 🖼️ Achievement Image Support Guide

## 📋 **Kullanım Seçenekleri**

Roqua achievement sisteminde artık **3 farklı ikon türü** kullanabilirsin:

### **1️⃣ SF Symbols (Varsayılan)**
```json
{
  "iconName": "trophy.fill",
  "imageName": null
}
```

### **2️⃣ Custom Images**  
```json
{
  "iconName": "trophy.fill",
  "imageName": "custom_trophy_bronze"
}
```

### **3️⃣ Hybrid (Fallback)**
```json
{
  "iconName": "trophy.fill",
  "imageName": "my_custom_icon"
}
```
> İmage yoksa otomatik olarak SF Symbol kullanır

---

## 🎯 **Custom Image Ekleme Süreci**

### **1️⃣ Assets'e Image Ekleme**
1. Xcode'da **Assets.xcassets**'i aç
2. **+ > Image Set** ile yeni image set oluştur
3. Dosya adını ver (örn: `custom_trophy_bronze`)
4. PNG/SVG dosyalarını sürükle:
   - `@1x` → 64x64px
   - `@2x` → 128x128px  
   - `@3x` → 192x192px

### **2️⃣ JSON'da Kullanım**
```json
{
  "id": "special_achievement",
  "title": "Özel Başarım",
  "description": "Custom iconlu achievement",
  "iconName": "trophy.fill",
  "imageName": "custom_trophy_bronze",
  "rarity": "epic",
  "category": "explorer",
  "type": "milestone",
  "target": 100,
  "calculator": "milestone",
  "parameters": {}
}
```

### **3️⃣ Otomatik Entegrasyon**
Sistem otomatik olarak:
- `achievement.isCustomImage` → `true` olur
- `AchievementIconView` custom image'i kullanır
- Fallback için SF Symbol hazır bekler

---

## 🔧 **AchievementIconView Kullanımı**

### **Mevcut Component'lar**
```swift
// Farklı boyutlar
AchievementIconView.small(achievement)    // 20px
AchievementIconView.medium(achievement)   // 30px  
AchievementIconView.large(achievement)    // 40px
AchievementIconView.extraLarge(achievement) // 60px

// Manuel boyut
AchievementIconView(achievement: achievement, size: 50, weight: .bold)
```

### **Otomatik Özellikler**
- ✅ **Responsive**: SF Symbol + Custom Image desteği
- ✅ **Fallback**: Image yoksa SF Symbol kullanır
- ✅ **Consistent**: Aynı shadow, color, style
- ✅ **Performance**: Lazy loading + caching

---

## 🎨 **Design Guidelines**

### **Image Specifications**
- **Format**: PNG (transparan arka plan) veya SVG
- **Size**: 64x64, 128x128, 192x192 (1x, 2x, 3x)
- **Style**: Basit, tanınabilir, medal theme'ine uygun
- **Color**: Beyaz/açık renkler (dark background'da kullanılacak)

### **Naming Convention**
```
achievement_[category]_[rarity]_[description]

Örnekler:
- achievement_explorer_rare_golden_compass
- achievement_city_epic_istanbul_master  
- achievement_milestone_legendary_world_explorer
```

### **Rarity-Based Design**
- **Common**: Gümüş/gri tonlar
- **Rare**: Altın/sarı tonlar  
- **Epic**: Mor/mavi tonlar
- **Legendary**: Turuncu/ateş tonları

---

## 📝 **Pratik Örnekler**

### **İstanbul Temalı Custom Achievement**
```json
{
  "id": "istanbul_master_custom",
  "title": "İstanbul Efsanesi", 
  "description": "İstanbul'un her köşesini keşfet",
  "iconName": "building.2.fill",
  "imageName": "achievement_istanbul_epic_bosphorus",
  "rarity": "epic",
  "category": "cityMaster",
  "type": "geographic",
  "target": 500,
  "calculator": "city",
  "parameters": {
    "cityName": "istanbul"
  }
}
```

### **Özel Milestone Achievement**
```json
{
  "id": "legendary_explorer_custom",
  "title": "Efsanevi Kaşif",
  "description": "50.000 bölge keşfederek tarihe geç",
  "iconName": "crown.fill", 
  "imageName": "achievement_milestone_legendary_crown",
  "rarity": "legendary",
  "category": "worldTraveler",
  "type": "milestone", 
  "target": 50000,
  "calculator": "milestone",
  "parameters": {}
}
```

---

## 🚀 **Migration Path**

### **Mevcut Achievements**
- ✅ Hiçbir şey değişmiyor
- ✅ `imageName: null` → SF Symbol kullanmaya devam
- ✅ Backward compatible

### **Yeni Achievements**
- 🎯 `imageName` field'ı ekleyerek custom image kullan
- 🎯 İstersen SF Symbol'de kalabilirsin
- 🎯 İkisini birden kullanabilirsin (fallback için)

### **Gelişmiş Kullanım**
```swift
// Code'da manuel kontrol
if achievement.isCustomImage {
    // Custom image logic
} else {
    // SF Symbol logic
}

// Display icon (her zaman çalışır)
let displayIcon = achievement.displayIcon
```

---

## ⚡ **Best Practices**

### **✅ DO**
- Custom image'ları Assets.xcassets'e ekle
- 3 farklı resolution sağla (@1x, @2x, @3x)
- Transparan background kullan
- Rarity'ye uygun renkler seç
- Fallback SF Symbol belirle

### **❌ DON'T**  
- Çok detaylı/karışık design yapma
- Çok büyük dosya boyutu kullanma
- Sadece 1x resolution koy
- Opak background kullan
- SF Symbol fallback atla

---

## 🧪 **Test Checklist**

### **Görsel Test**
- [ ] Custom image düzgün görünüyor
- [ ] SF Symbol fallback çalışıyor  
- [ ] Tüm cihazlarda responsive
- [ ] Shadow/color efektleri doğru

### **Performance Test**
- [ ] Image loading hızlı
- [ ] Memory usage normal
- [ ] Scroll performance iyi
- [ ] Build size artışı minimal

### **Fonksiyon Test**
- [ ] Achievement unlock animasyonu
- [ ] Detail sheet görünümü
- [ ] Medal card display
- [ ] Notification gösterimi

---

**🎯 Artık hem SF Symbol hem custom image kullanabilirsin! Her ikisi de aynı code base'de sorunsuz çalışıyor.** 