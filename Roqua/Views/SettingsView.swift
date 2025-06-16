import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetAlert = false
    @State private var showingDataResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Location Tracking Section
                Section {
                    // Tracking Distance
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.circle")
                                .foregroundColor(.blue)
                            Text("Konum Takip Mesafesi")
                                .font(.headline)
                        }
                        
                        Picker("Tracking Distance", selection: $settings.locationTrackingDistance) {
                            ForEach(AppSettings.trackingDistanceOptions, id: \.value) { option in
                                VStack(alignment: .leading) {
                                    Text(option.label)
                                        .font(.body)
                                    Text(option.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(option.value)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text("Mevcut: \(settings.currentTrackingOption.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Auto Map Centering
                    HStack {
                        Image(systemName: "scope")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Otomatik Harita Ortalama")
                                .font(.headline)
                            Text("Konum değişiminde haritayı otomatik ortala")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.autoMapCentering)
                    }
                    
                    // Preserve Zoom/Pan
                    HStack {
                        Image(systemName: "hand.draw")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Zoom/Pan Koruması")
                                .font(.headline)
                            Text("Kullanıcı etkileşimlerini koru")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.preserveZoomPan)
                    }
                    
                } header: {
                    Label("Konum Takibi", systemImage: "location")
                }
                
                // MARK: - Exploration Section
                Section {
                    // Exploration Radius
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "circle.dashed")
                                .foregroundColor(.purple)
                            Text("Keşif Radius'u")
                                .font(.headline)
                        }
                        
                        Picker("Exploration Radius", selection: $settings.explorationRadius) {
                            ForEach(AppSettings.radiusOptions, id: \.value) { option in
                                VStack(alignment: .leading) {
                                    Text(option.label)
                                        .font(.body)
                                    Text(option.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(option.value)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text("Mevcut: \(settings.currentRadiusOption.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Accuracy Threshold
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.red)
                            Text("Doğruluk Eşiği")
                                .font(.headline)
                        }
                        
                        Picker("Accuracy Threshold", selection: $settings.accuracyThreshold) {
                            ForEach(AppSettings.accuracyOptions, id: \.value) { option in
                                VStack(alignment: .leading) {
                                    Text(option.label)
                                        .font(.body)
                                    Text(option.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(option.value)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text("Mevcut: \(settings.currentAccuracyOption.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Clustering Radius
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "circle.grid.cross")
                                .foregroundColor(.indigo)
                            Text("Gruplandırma Radius'u")
                                .font(.headline)
                        }
                        
                        Picker("Clustering Radius", selection: $settings.clusteringRadius) {
                            ForEach(AppSettings.clusteringOptions, id: \.value) { option in
                                VStack(alignment: .leading) {
                                    Text(option.label)
                                        .font(.body)
                                    Text(option.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(option.value)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Text("Mevcut: \(settings.currentClusteringOption.description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                } header: {
                    Label("Keşif Ayarları", systemImage: "map")
                }
                
                // MARK: - Grid & Percentage Section
                Section {

                    // Percentage Decimals
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "percent")
                                .foregroundColor(.mint)
                            Text("Yüzde Hassasiyeti")
                                .font(.headline)
                        }
                        
                        Picker("Basamak", selection: $settings.percentageDecimals) {
                            Text("4 basamaklı").tag(4)
                            Text("5 basamaklı").tag(5)
                            Text("6 basamaklı").tag(6)
                            Text("7 basamaklı").tag(7)
                            Text("8 basamaklı").tag(8)
                            Text("9 basamaklı").tag(9)
                        }
                        .pickerStyle(.menu)
                        
                        Text("Mevcut: \(GridHashManager.shared.getExplorationPercentage()) keşfedildi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Enable Exploration Stats
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Keşif İstatistikleri")
                                .font(.headline)
                            Text("Real-time yüzde hesaplama")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.enableExplorationStats)
                    }
                    
                } header: {
                    Label("Grid & Yüzde Ayarları", systemImage: "chart.pie")
                }
                
                // MARK: - Map Section
                Section {
                    // Map Type
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "map")
                                .foregroundColor(.blue)
                            Text("Harita Türü")
                                .font(.headline)
                        }
                        
                        Picker("Map Type", selection: $settings.mapType) {
                            Text("Standart").tag(0)
                            Text("Uydu").tag(1)
                            Text("Hibrit").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Show User Location
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Kullanıcı Konumunu Göster")
                                .font(.headline)
                            Text("Haritada mavi nokta göster")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.showUserLocation)
                    }
                    
                    // Enable Pitch
                    HStack {
                        Image(systemName: "rotate.3d")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading) {
                            Text("3D Eğim")
                                .font(.headline)
                            Text("Harita eğimini etkinleştir")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.enablePitch)
                    }
                    
                    // Enable Rotation
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading) {
                            Text("Harita Döndürme")
                                .font(.headline)
                            Text("Harita döndürmeyi etkinleştir")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.enableRotation)
                    }
                    
                } header: {
                    Label("Harita Ayarları", systemImage: "map.fill")
                }
                
                // MARK: - Privacy Section
                Section {
                    // Enable Reverse Geocoding
                    HStack {
                        Image(systemName: "globe.americas.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Reverse Geocoding")
                                .font(.headline)
                            Text("Bölgelere şehir/ülke bilgisi ekle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.enableReverseGeocoding)
                    }
                    
                    // Auto Enrich New Regions
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Otomatik Zenginleştirme")
                                .font(.headline)
                            Text("Yeni bölgeleri otomatik zenginleştir")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.autoEnrichNewRegions)
                            .disabled(!settings.enableReverseGeocoding)
                    }
                    
                    // Batch Enrich on Startup
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Başlangıçta Toplu İşlem")
                                .font(.headline)
                            Text("Uygulama açılışında eksik bölgeleri zenginleştir")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.batchEnrichOnStartup)
                            .disabled(!settings.enableReverseGeocoding)
                    }
                    
                    // Enable Geocoding (eski)
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Coğrafi Kodlama")
                                .font(.headline)
                            Text("Şehir/ülke bilgilerini al")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.enableGeocoding)
                    }
                    
                    // Offline Mode
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Çevrimdışı Mod")
                                .font(.headline)
                            Text("İnternet bağlantısı kullanma")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.offlineMode)
                    }
                    
                    // Manual Batch Enrich Button
                    if settings.enableReverseGeocoding {
                        Button(action: {
                            Task { @MainActor in
                                ReverseGeocoder.shared.enrichUnenrichedRegions()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.white)
                                Text("Eksik Bölgeleri Zenginleştir")
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                } header: {
                    Label("Gizlilik", systemImage: "lock.shield")
                }
                
                // MARK: - Performance Section
                Section {
                    // Max Regions in Memory
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "memorychip")
                                .foregroundColor(.red)
                            Text("Bellekteki Maksimum Bölge")
                                .font(.headline)
                        }
                        
                        HStack {
                            Text("100")
                                .font(.caption)
                            Slider(value: Binding(
                                get: { Double(settings.maxRegionsInMemory) },
                                set: { settings.maxRegionsInMemory = Int($0) }
                            ), in: 100...5000, step: 100)
                            Text("5000")
                                .font(.caption)
                        }
                        
                        Text("Mevcut: \(settings.maxRegionsInMemory) bölge")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Background Processing
                    HStack {
                        Image(systemName: "gearshape.2")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Arka Plan İşleme")
                                .font(.headline)
                            Text("Arka planda veri işle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.backgroundProcessing)
                    }
                    
                } header: {
                    Label("Performans", systemImage: "speedometer")
                }
                
                // MARK: - Reset Section
                Section {
                    Button(action: {
                        showingDataResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Tüm Keşif Verilerini Sil")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.orange)
                            Text("Varsayılan Ayarlara Sıfırla")
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Label("Sıfırlama", systemImage: "trash")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
            .alert("Ayarları Sıfırla", isPresented: $showingResetAlert) {
                Button("Sıfırla", role: .destructive) {
                    settings.resetToDefaults()
                }
                Button("İptal", role: .cancel) { }
            } message: {
                Text("Tüm ayarlar varsayılan değerlerine sıfırlanacak. Bu işlem geri alınamaz.")
            }
            .alert("Keşif Verilerini Sil", isPresented: $showingDataResetAlert) {
                Button("Sil", role: .destructive) {
                    clearAllData()
                }
                Button("İptal", role: .cancel) { }
            } message: {
                Text("Tüm keşfedilen bölgeler ve SQLite veritabanı silinecek. Bu işlem geri alınamaz.")
            }
        }
    }
    
    private func clearAllData() {
        print("🗑️ Starting complete data clearing process...")
        
        // 1. VisitedRegionManager - SQLite veritabanı ve memory'deki region'ları temizle
        VisitedRegionManager.shared.clearAllData()
        print("✅ VisitedRegionManager cleared")
        
        // 2. GridHashManager - Grid hash'leri ve UserDefaults'u temizle
        GridHashManager.shared.clearAll()
        print("✅ GridHashManager cleared")
        
        // 3. ExploredCirclesManager - Fog of War koordinatlarını ve UserDefaults'u temizle
        ExploredCirclesManager.shared.clearAllData()
        print("✅ ExploredCirclesManager cleared")
        
        // 4. Achievement Progress'i temizle (opsiyonel - başarımlar sıfırlanır)
        AchievementManager.shared.resetAllProgress()
        print("✅ Achievement progress reset")
        
        // 5. ReverseGeocoder cache'ini temizle
        ReverseGeocoder.shared.clearCache()
        print("✅ ReverseGeocoder cache cleared")
        
        print("🎉 All exploration data cleared successfully!")
        print("📊 Next location update will start fresh exploration")
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 