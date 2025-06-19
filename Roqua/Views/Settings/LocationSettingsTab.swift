import SwiftUI

struct LocationSettingsTab: View {
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        Form {
            // MARK: - Location Tracking Section
            Section("Konum Takibi") {
                // Tracking Distance - Slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "location.circle")
                            .foregroundColor(.blue)
                        Text("Konum Takip Mesafesi")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(settings.locationTrackingDistance))m")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Slider(
                        value: $settings.locationTrackingDistance,
                        in: AppSettings.minTrackingDistance...AppSettings.maxTrackingDistance,
                        step: AppSettings.trackingStep
                    ) {
                        Text("Konum Takip Mesafesi")
                    } minimumValueLabel: {
                        Text("\(Int(AppSettings.minTrackingDistance))m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("\(Int(AppSettings.maxTrackingDistance))m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tint(.blue)
                    
                    Text("Düşük değerler daha sık konum güncellemesi, yüksek değerler pil tasarrufu sağlar")
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
                
                // Accuracy Threshold - Slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.red)
                        Text("Doğruluk Eşiği")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(settings.accuracyThreshold))m")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    Slider(
                        value: $settings.accuracyThreshold,
                        in: AppSettings.minAccuracyThreshold...AppSettings.maxAccuracyThreshold,
                        step: AppSettings.accuracyStep
                    ) {
                        Text("Doğruluk Eşiği")
                    } minimumValueLabel: {
                        Text("\(Int(AppSettings.minAccuracyThreshold))m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("\(Int(AppSettings.maxAccuracyThreshold))m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tint(.red)
                    
                    Text("Düşük değerler daha hassas konum, yüksek değerler daha hızlı güncellemeler sağlar")
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