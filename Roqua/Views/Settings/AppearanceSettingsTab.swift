import SwiftUI
import MapKit

struct AppearanceSettingsTab: View {
    @StateObject private var settings = AppSettings.shared
    
    private var colorSchemeDescription: String {
        switch settings.colorScheme {
        case 0:
            return "Sistem ayarlarını takip eder"
        case 1:
            return "Her zaman açık tema kullanılır"
        case 2:
            return "Her zaman koyu tema kullanılır"
        default:
            return "Sistem ayarlarını takip eder"
        }
    }
    
    var body: some View {
        Form {
            // MARK: - Theme Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.blue)
                        Text("Tema")
                            .font(.headline)
                    }
                    
                    Picker("Tema", selection: $settings.colorScheme) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Sistem Varsayılanı")
                        }.tag(0)
                        
                        HStack {
                            Image(systemName: "sun.max.fill")
                            Text("Açık Tema")
                        }.tag(1)
                        
                        HStack {
                            Image(systemName: "moon.fill")
                            Text("Koyu Tema")
                        }.tag(2)
                    }
                    .pickerStyle(.menu)
                    
                    Text(colorSchemeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Görünüm Teması")
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
                    
                    Picker("Harita Türü", selection: $settings.mapType) {
                        Text("Standart").tag(0)
                        Text("Uydu").tag(1)
                        Text("Hibrit").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Show User Location
                HStack {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Kullanıcı Konumunu Göster")
                            .font(.headline)
                        Text("Haritada mavi nokta ile konumu göster")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $settings.showUserLocation)
                }
                
                // Pitch Enabled (3D Tilt)
                HStack {
                    Image(systemName: "view.3d")
                        .foregroundColor(.purple)
                    VStack(alignment: .leading) {
                        Text("3D Eğim")
                            .font(.headline)
                        Text("Haritayı eğik açıyla görüntüle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $settings.enablePitch)
                }
                
                // Rotation Enabled
                HStack {
                    Image(systemName: "rotate.3d")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Harita Döndürme")
                            .font(.headline)
                        Text("Touch ile haritayı döndürme")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $settings.enableRotation)
                }
                
            } header: {
                Text("Harita Görünümü")
            }
        }
        .navigationTitle("Görünüm")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview
struct AppearanceSettingsTab_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppearanceSettingsTab()
        }
    }
} 