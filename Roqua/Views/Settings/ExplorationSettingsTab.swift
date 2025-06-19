import SwiftUI

struct ExplorationSettingsTab: View {
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        Form {
            // MARK: - Exploration Section
            Section("Keşif Ayarları") {
                // Exploration Radius - Slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "circle.dashed")
                            .foregroundColor(.purple)
                        Text("Keşif Radius'u")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(settings.explorationRadius))m")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    
                    Slider(
                        value: $settings.explorationRadius,
                        in: AppSettings.minExplorationRadius...AppSettings.maxExplorationRadius,
                        step: AppSettings.radiusStep
                    ) {
                        Text("Keşif Radius'u")
                    } minimumValueLabel: {
                        Text("\(Int(AppSettings.minExplorationRadius))m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("\(Int(AppSettings.maxExplorationRadius))m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tint(.purple)
                    
                    Text("Düşük değerler daha detaylı keşif sağlar, yüksek değerler pil ömrünü korur")
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
                
            }
            
            // MARK: - Grid & Percentage Section
            Section("Grid & Yüzde Ayarları") {
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
                
            }
        }
        .navigationTitle("Keşif")
        .navigationBarTitleDisplayMode(.large)

    }
}

// MARK: - Preview
struct ExplorationSettingsTab_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExplorationSettingsTab()
        }
    }
} 