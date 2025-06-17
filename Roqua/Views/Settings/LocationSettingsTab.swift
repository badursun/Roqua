import SwiftUI

struct LocationSettingsTab: View {
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        Form {
            // MARK: - Location Tracking Section
            Section("Konum Takibi") {
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
                
            }
        }
        .navigationTitle("Konum")
        .navigationBarTitleDisplayMode(.large)

    }
}

// MARK: - Preview
struct LocationSettingsTab_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LocationSettingsTab()
        }
    }
} 