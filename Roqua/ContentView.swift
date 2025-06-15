//
//  ContentView.swift
//  Roqua
//
//  Created by Anthony Burak DURSUN on 15.06.2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var exploredCirclesManager = ExploredCirclesManager()
    @StateObject private var visitedRegionManager = VisitedRegionManager.shared
    @StateObject private var reverseGeocoder = ReverseGeocoder.shared
    @StateObject private var gridHashManager = GridHashManager.shared
    @State private var position = MapCameraPosition.automatic
    @State private var showingSettings = false
    @State private var showingAccount = false
    @State private var hasInitialized = false
    @State private var currentZoomLevel: String = "1:200m"
    
    private var isLocationTrackingActive: Bool {
        return locationManager.isFullyAuthorized && CLLocationManager.locationServicesEnabled()
    }

    var body: some View {
        ZStack {
            // Tam Ekran Harita
            FogOfWarMapView(
                locationManager: locationManager,
                exploredCirclesManager: exploredCirclesManager,
                visitedRegionManager: visitedRegionManager,
                position: $position,
                currentZoomLevel: $currentZoomLevel
            )
            .ignoresSafeArea(.all)
            
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
                
                BottomControlPanel(locationManager: locationManager, reverseGeocoder: reverseGeocoder, gridHashManager: gridHashManager, position: $position, currentZoomLevel: $currentZoomLevel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAccount) {
            AccountView()
        }
        .onAppear {
            // Uygulama açıldığında konum güncellemelerini başlat
            if locationManager.isFullyAuthorized {
                locationManager.startLocationUpdates()
            }
            
            // İlk kez açılışta migration yap
            if !hasInitialized {
                performMigrationIfNeeded()
                hasInitialized = true
            }
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if let location = newLocation {
                exploredCirclesManager.addLocation(location)
                visitedRegionManager.processNewLocation(location)
                reverseGeocoder.geocodeLocation(location)
            }
        }
    }
    
    // MARK: - Migration
    private func performMigrationIfNeeded() {
        // Eğer VisitedRegionManager boşsa ve ExploredCircles varsa migration yap
        if visitedRegionManager.visitedRegions.isEmpty && !exploredCirclesManager.exploredCircles.isEmpty {
            print("🔄 Starting migration from ExploredCircles to VisitedRegions...")
            visitedRegionManager.migrateFromExploredCircles(exploredCirclesManager.exploredCircles)
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
    @ObservedObject var reverseGeocoder: ReverseGeocoder
    @ObservedObject var gridHashManager: GridHashManager
    @Binding var position: MapCameraPosition
    @Binding var currentZoomLevel: String
    // explorationPercentage artık gridHashManager'dan gelecek
    
    private var isLocationTrackingActive: Bool {
        return locationManager.isFullyAuthorized && CLLocationManager.locationServicesEnabled()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // İstatistik Kartı
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keşfedilen Alan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(gridHashManager.formattedPercentage)
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
                    if isLocationTrackingActive, let currentLocation = locationManager.currentLocation {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            position = .region(MKCoordinateRegion(
                                center: currentLocation.coordinate,
                                latitudinalMeters: 200,
                                longitudinalMeters: 200
                            ))
                        }
                    } else if !locationManager.isFullyAuthorized {
                        // İzin yoksa ayarlara yönlendir
                        locationManager.openSettings()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isLocationTrackingActive ? "location.fill" : "location.slash.fill")
                            .font(.callout)
                        Text(isLocationTrackingActive ? "Konumum" : "Konum Kapalı")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: isLocationTrackingActive ? 
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                    )
                }
            }
            
            // Bilgi Çubuğu (Alt kısım)
            HStack(spacing: 16) {
                // Konum Bilgisi
                HStack(spacing: 6) {
                    Image(systemName: "location.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    
                    Text(reverseGeocoder.currentLocationInfo?.shortDisplayText ?? "Konum alınıyor...")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                // Zoom Seviyesi
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    
                    Text(currentZoomLevel)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                
                // GPS Doğruluğu
                if let location = locationManager.currentLocation {
                    HStack(spacing: 6) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        
                        Text("±\(Int(location.horizontalAccuracy))m")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            )
        }
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

// Map view artık ayrı dosyada - Views/MapView/FogOfWarMapView.swift

#Preview {
    ContentView()
}
