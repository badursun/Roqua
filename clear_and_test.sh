#!/bin/bash

echo "🧹 Clearing all data and testing new GridHashManager..."

# 1. Simülatörü reset et (tüm verileri sil)
echo "📱 Resetting simulator data..."
xcrun simctl shutdown booted
xcrun simctl erase booted
xcrun simctl boot booted

# 2. Uygulamayı yeniden install et
echo "📦 Installing fresh app..."
xcrun simctl install booted /Users/burakyeni/Library/Developer/Xcode/DerivedData/Roqua-geetxjouftotfielfvbhdpjjakry/Build/Products/Debug-iphonesimulator/Roqua.app

# 3. Uygulamayı başlat
echo "🚀 Launching app..."
xcrun simctl launch booted com.adjans.roqua.Roqua

# 4. Konum izni için bekle
echo "⏳ Waiting for location permission (10 seconds)..."
sleep 10

# 5. Test rotasını çalıştır
echo "🗺️ Running test route..."
./test_gpx_route.sh gpx_files/test-2.gpx 1

echo "✅ Test completed! Check the app for new grid results." 