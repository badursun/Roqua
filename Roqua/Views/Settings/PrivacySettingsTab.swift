import SwiftUI

struct PrivacySettingsTab: View {
    @StateObject private var settings = AppSettings.shared
    @State private var showingEnrichmentAlert = false
    
    var body: some View {
        Form {
            // MARK: - Privacy Section
            VStack(spacing: 16) {
                Text("Gizlilik Ayarları")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    // Reverse Geocoding
                    HStack {
                        Image(systemName: "location.magnifyingglass")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Reverse Geocoding")
                                .font(.headline)
                            Text("Koordinatları adres bilgisine çevir")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.enableReverseGeocoding)
                    }
                    
                    // Auto Enrichment
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Otomatik Zenginleştirme")
                                .font(.headline)
                            Text("Yeni bölgeleri otomatik zenginleştir")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.enableAutoEnrichment)
                    }
                    
                    // Bulk Process on Launch
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Başlangıçta Toplu İşlem")
                                .font(.headline)
                            Text("Uygulama açılırken eksik bölgeleri işle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.enableBulkProcessOnLaunch)
                    }
                    
                    // Geocoding Enabled
                    HStack {
                        Image(systemName: "globe.americas")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Coğrafi Kodlama")
                                .font(.headline)
                            Text("Konum adlandırma hizmeti")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.enableGeocoding)
                    }
                    
                    // Offline Mode
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Çevrimdışı Mod")
                                .font(.headline)
                            Text("Tüm online özellikleri devre dışı bırak")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.offlineMode)
                    }
                }
            }
            .padding()
            
            // MARK: - Data Management Section
            VStack(spacing: 16) {
                Text("Veri Yönetimi")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Enrich Missing Regions Button
                Button(action: {
                    showingEnrichmentAlert = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.blue)
                        Text("Eksik Bölgeleri Zenginleştir")
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(getUnenrichedCount()) bölge")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .alert("Bölge Zenginleştirme", isPresented: $showingEnrichmentAlert) {
                    Button("Başlat", role: .destructive) {
                        enrichMissingRegions()
                    }
                    Button("İptal", role: .cancel) { }
                } message: {
                    Text("Bu işlem eksik coğrafi bilgileri tamamlayacak. Devam edilsin mi?")
                }
            }
            .padding()
        }
        .navigationTitle("Gizlilik")
        .navigationBarTitleDisplayMode(.large)

    }
    
    // MARK: - Helper Methods
    private func getUnenrichedCount() -> Int {
        // Placeholder - implement in SQLiteManager if needed
        return 0
    }
    
    private func enrichMissingRegions() {
        Task {
            // Placeholder - implement enrichment logic
            print("Enriching missing regions...")
        }
    }
}

// MARK: - Preview
struct PrivacySettingsTab_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacySettingsTab()
        }
    }
} 