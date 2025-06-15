#!/bin/bash

# Roqua GPX Route Test Script
# İstanbul Comprehensive Tour Route Test

echo "🗺️  Roqua GPX Route Test - İstanbul Comprehensive Tour"
echo "=================================================="

# GPX dosyası kontrolü
GPX_FILE="gpx_files/istanbul_gezi_rotasi.gpx"

if [ ! -f "$GPX_FILE" ]; then
    echo "❌ GPX dosyası bulunamadı: $GPX_FILE"
    exit 1
fi

echo "✅ GPX dosyası bulundu: $GPX_FILE"

# Simulator kontrolü
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep "Booted" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')

if [ -z "$SIMULATOR_ID" ]; then
    echo "📱 iPhone 16 Pro simulator başlatılıyor..."
    open -a Simulator
    sleep 5
    
    # iPhone 16 Pro'yu boot et
    DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')
    if [ ! -z "$DEVICE_ID" ]; then
        xcrun simctl boot "$DEVICE_ID"
        sleep 3
        SIMULATOR_ID=$DEVICE_ID
    fi
fi

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ iPhone 16 Pro simulator bulunamadı"
    exit 1
fi

echo "✅ Simulator hazır: $SIMULATOR_ID"

# Roqua uygulamasını kontrol et
APP_BUNDLE="com.adjans.roqua.Roqua"
APP_INSTALLED=$(xcrun simctl get_app_container booted "$APP_BUNDLE" 2>/dev/null)

if [ -z "$APP_INSTALLED" ]; then
    echo "❌ Roqua uygulaması yüklü değil. Önce build edin."
    exit 1
fi

echo "✅ Roqua uygulaması yüklü"

# Konum izinlerini ayarla
echo "🔐 Konum izinleri ayarlanıyor..."
xcrun simctl privacy booted grant location "$APP_BUNDLE"
xcrun simctl privacy booted grant location-always "$APP_BUNDLE"

# Uygulamayı başlat
echo "🚀 Roqua uygulaması başlatılıyor..."
xcrun simctl launch booted "$APP_BUNDLE"
sleep 3

# GPX route'unu başlat
echo "🗺️  GPX route başlatılıyor: İstanbul Comprehensive Tour"
echo "📍 Rota: Sultanahmet → Galata → Beşiktaş → Ortaköy → Bebek → Sarıyer"
echo "⏱️  Süre: ~5 dakika (4.5 saat simülasyonu)"
echo "📊 Beklenen sonuç: Exploration percentage artışı"

xcrun simctl location booted "$GPX_FILE"

echo ""
echo "🎯 Test başlatıldı!"
echo "📱 Simulator'da Roqua uygulamasını izleyin"
echo "📈 Bottom panel'de exploration percentage artışını gözlemleyin"
echo "⚙️  Settings'den decimal hassasiyetini değiştirebilirsiniz"
echo ""
echo "🛑 Test'i durdurmak için: Ctrl+C"
echo "📍 Manuel konum için: xcrun simctl location booted set <lat> <lon>"

# Test süresince bekle
echo "⏳ Test devam ediyor... (5 dakika)"
sleep 300

echo ""
echo "✅ Test tamamlandı!"
echo "📊 Sonuçları kontrol edin:"
echo "   - Exploration percentage artışı"
echo "   - Fog of war alanları"
echo "   - Grid hash sayısı" 