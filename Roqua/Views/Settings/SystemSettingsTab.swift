import SwiftUI

struct SystemSettingsTab: View {
    @StateObject private var settings = AppSettings.shared
    @State private var showingResetAllAlert = false
    @State private var showingClearDataAlert = false
    
    var body: some View {
        Form {
            // MARK: - Performance Section
            Section {
                // Max Regions in Memory
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "memorychip")
                            .foregroundColor(.blue)
                        Text("Bellekteki Maksimum Bölge")
                            .font(.headline)
                    }
                    
                    VStack(spacing: 8) {
                        Slider(
                            value: Binding(
                                get: { Double(settings.maxRegionsInMemory) },
                                set: { settings.maxRegionsInMemory = Int($0) }
                            ),
                            in: 100...5000,
                            step: 100
                        )
                        
                        HStack {
                            Text("100")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(settings.maxRegionsInMemory)")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            Spacer()
                            Text("5000")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Daha yüksek değerler daha fazla bellek kullanır")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Background Location
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Arka Plan Konum Takibi")
                            .font(.headline)
                        Text("Uygulama kapalıyken konum kaydı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $settings.backgroundLocationEnabled)
                }
                
            } header: {
                Text("Performans")
            }
            
            // MARK: - Reset Section
            Section {
                // Reset to Defaults
                Button(action: {
                    showingResetAllAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.orange)
                        Text("Varsayılan Ayarlara Sıfırla")
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
                .alert("Ayarları Sıfırla", isPresented: $showingResetAllAlert) {
                    Button("Sıfırla", role: .destructive) {
                        resetToDefaults()
                    }
                    Button("İptal", role: .cancel) { }
                } message: {
                    Text("Tüm ayarlar varsayılan değerlere sıfırlanacak. Bu işlem geri alınamaz.")
                }
                
                // Clear All Data
                Button(action: {
                    showingClearDataAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Tüm Keşif Verilerini Sil")
                            .foregroundColor(.red)
                        Spacer()
                        Text("\(getTotalRegionsCount()) bölge")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .alert("Veri Silme", isPresented: $showingClearDataAlert) {
                    Button("Sil", role: .destructive) {
                        clearAllData()
                    }
                    Button("İptal", role: .cancel) { }
                } message: {
                    Text("Tüm keşif verileri kalıcı olarak silinecek. Bu işlem geri alınamaz!")
                }
                
            } header: {
                Text("Sıfırlama")
            }
            
            Section {
                EmptyView()
            } footer: {
                Text("⚠️ Dikkat: Sıfırlama işlemleri geri alınamaz")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Sistem")
        .navigationBarTitleDisplayMode(.large)

    }
    
    // MARK: - Helper Methods
    private func getTotalRegionsCount() -> Int {
        // Placeholder - implement in SQLiteManager if needed
        return 0 // GridHashManager.shared.getAllRegions().count
    }
    
    private func resetToDefaults() {
        // Reset settings to default values
        settings.resetToDefaults()
    }
    
    private func clearAllData() {
        Task {
            do {
                // Clear all exploration data
                // GridHashManager.shared.clearCache()
                print("All data cleared successfully (placeholder)")
            } catch {
                print("Clear data error: \(error)")
            }
        }
    }
}

// MARK: - Preview
struct SystemSettingsTab_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SystemSettingsTab()
        }
    }
} 