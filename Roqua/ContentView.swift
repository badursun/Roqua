//
//  ContentView.swift
//  Roqua
//
//  Created by Anthony Burak DURSUN on 15.06.2025.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var position = MapCameraPosition.automatic
    @State private var showingSettings = false
    @State private var showingAccount = false
    
    var body: some View {
        ZStack {
            // Tam Ekran Harita
            Map(position: $position) {
                // Mevcut konum annotation
                if let currentLocation = locationManager.currentLocation {
                    Annotation("Konumun", coordinate: currentLocation.coordinate) {
                        Circle()
                            .fill(.blue)
                            .stroke(.white, lineWidth: 2)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .ignoresSafeArea(.all)
            .onChange(of: locationManager.currentLocation) { _, newLocation in
                if let location = newLocation {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        position = .camera(MapCamera(
                            centerCoordinate: location.coordinate,
                            distance: 1000
                        ))
                    }
                }
            }
            
            // Top Navigation
            VStack {
                HStack {
                    // Sol - Hesap Butonu
                    Button(action: { showingAccount = true }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                            )
                    }
                    
                    Spacer()
                    
                    // Konum Durumu Göstergesi
                    LocationStatusIndicator(locationManager: locationManager)
                    
                    Spacer()
                    
                    // Sağ - Menü Butonu
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            
            // Bottom Controller Panel
            VStack {
                Spacer()
                
                BottomControlPanel(locationManager: locationManager)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSettings) {
            SettingsView(locationManager: locationManager)
        }
        .sheet(isPresented: $showingAccount) {
            AccountView()
        }
        .onAppear {
            // Uygulama açıldığında konum güncellemelerini başlat
            if locationManager.isFullyAuthorized {
                locationManager.startLocationUpdates()
            }
        }
    }
}

// MARK: - Location Status Indicator
struct LocationStatusIndicator: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch locationManager.permissionState {
        case .alwaysGranted:
            return .green
        case .whenInUseGranted:
            return .orange
        case .denied, .restricted:
            return .red
        default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch locationManager.permissionState {
        case .alwaysGranted:
            return "Aktif"
        case .whenInUseGranted:
            return "Kısıtlı"
        case .denied:
            return "Kapalı"
        case .restricted:
            return "Kısıtlı"
        default:
            return "Bekliyor"
        }
    }
}

struct BottomControlPanel: View {
    @ObservedObject var locationManager: LocationManager
    @State private var explorationPercentage: Double = 2.13
    
    var body: some View {
        VStack(spacing: 16) {
            // İstatistik Kartı
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keşfedilen Alan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(explorationPercentage, specifier: "%.2f")")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("%")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Dünya ikonu
                    Image(systemName: "globe")
                        .font(.title)
                        .foregroundStyle(.blue)
                    
                    // Konum durumu
                    if let location = locationManager.currentLocation {
                        Text("GPS: ±\(Int(location.horizontalAccuracy))m")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            
            // Aksiyon Butonları
            HStack(spacing: 12) {
                // Konumum Butonu
                Button(action: {
                    if let location = locationManager.currentLocation {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            // position güncelleme kodu buraya gelecek
                        }
                    } else if !locationManager.isFullyAuthorized {
                        // İzin yoksa ayarlara yönlendir
                        locationManager.openSettings()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: locationManager.currentLocation != nil ? "location.fill" : "location.slash.fill")
                            .font(.callout)
                        Text(locationManager.currentLocation != nil ? "Konumum" : "Konum Kapalı")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: locationManager.currentLocation != nil ? 
                                        [.blue, .blue.opacity(0.8)] : 
                                        [.red.opacity(0.8), .red.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                
                // İstatistikler Butonu
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.callout)
                        Text("İstatistikler")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                    )
                }
            }
        }
    }
}

// MARK: - Settings View (Güncellenmiş)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Konum Ayarları") {
                    HStack {
                        Image(systemName: "location")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Konum İzni")
                            Text(permissionDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(permissionButtonText) {
                            if locationManager.permissionState == .denied || locationManager.permissionState == .restricted {
                                locationManager.openSettings()
                            } else if locationManager.canRequestAlwaysPermission {
                                locationManager.requestAlwaysPermission()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(!canRequestPermission)
                    }
                    
                    if locationManager.isFullyAuthorized {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("Konum Takibi")
                            
                            Spacer()
                            
                            Text(locationManager.currentLocation != nil ? "Aktif" : "Pasif")
                                .foregroundStyle(locationManager.currentLocation != nil ? .green : .red)
                        }
                    }
                }
                
                Section("Gizlilik") {
                    HStack {
                        Image(systemName: "trash")
                        Text("Veriyi Temizle")
                    }
                }
                
                Section("Görünüm") {
                    HStack {
                        Image(systemName: "map")
                        Text("Harita Stili")
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var permissionDescription: String {
        switch locationManager.permissionState {
        case .alwaysGranted:
            return "Sürekli izin verildi"
        case .whenInUseGranted:
            return "Sadece kullanırken"
        case .denied:
            return "İzin reddedildi"
        case .restricted:
            return "Kısıtlanmış"
        default:
            return "İzin bekleniyor"
        }
    }
    
    private var permissionButtonText: String {
        switch locationManager.permissionState {
        case .alwaysGranted:
            return "✓ Tam İzin"
        case .whenInUseGranted:
            return "Sürekli İzin"
        case .denied, .restricted:
            return "Ayarlar"
        default:
            return "İzin Ver"
        }
    }
    
    private var canRequestPermission: Bool {
        return locationManager.permissionState != .alwaysGranted
    }
}

// Hesap View aynı kalabilir
struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                VStack(spacing: 8) {
                    Text("Gizli Kaşif")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Kimlik gerekmez. Sadece keşfet.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Hesap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
