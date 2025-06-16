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
    @StateObject private var exploredCirclesManager = ExploredCirclesManager.shared
    @StateObject private var visitedRegionManager = VisitedRegionManager.shared
    @StateObject private var reverseGeocoder = ReverseGeocoder.shared
    @StateObject private var gridHashManager = GridHashManager.shared
    @StateObject private var notificationManager = AchievementNotificationManager.shared
    @State private var position = MapCameraPosition.automatic
    @State private var showingSettings = false
    @State private var showingAccount = false
    @State private var showingAchievements = false
    @State private var navigationPath = NavigationPath()
    @State private var hasInitialized = false
    @State private var currentZoomLevel: String = "1:200m"
    
    private var isLocationTrackingActive: Bool {
        return locationManager.isFullyAuthorized && CLLocationManager.locationServicesEnabled()
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
            // Tam Ekran Harita
            FogOfWarMapView(
                locationManager: locationManager,
                exploredCirclesManager: exploredCirclesManager,
                position: $position,
                currentZoomLevel: $currentZoomLevel
            )
            .ignoresSafeArea(.all)
            
                            // Top Navigation
            VStack {
                HStack {
                    // Sol - Hesap Butonu
                    Button(action: { showingAccount = true }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                    
                    // Spacing between Account and Achievement
                    Spacer()
                        .frame(width:8)
                    
                    // Achievement Butonu
                    Button(action: { 
                        navigationPath.append("achievements")
                    }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "trophy.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // Konum Durumu Göstergesi
                    LocationStatusIndicator(locationManager: locationManager)
                    
                    Spacer()
                    
                    // Sağ - Menü Butonu
                    Button(action: { showingSettings = true }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            
            // Bottom Controller Panel
            VStack {
                Spacer()
                
                BottomControlPanel(
                    locationManager: locationManager, 
                    exploredCirclesManager: exploredCirclesManager,
                    reverseGeocoder: reverseGeocoder, 
                    gridHashManager: gridHashManager, 
                    position: $position, 
                    currentZoomLevel: $currentZoomLevel
                )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
            }
            
            // Achievement Notification Overlay
            if notificationManager.isShowingNotification,
               let notification = notificationManager.currentNotification {
                VStack {
                    AchievementNotificationView(
                        achievement: notification.achievement,
                        progress: notification.progress,
                        isVisible: $notificationManager.isShowingNotification
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAccount) {
            AccountView()
        }
        .navigationDestination(for: String.self) { destination in
            switch destination {
            case "achievements":
                AchievementPageView()
            default:
                EmptyView()
            }
        }
        .onAppear {
            // Konum servislerini başlat
            Task { @MainActor in
                // Mevcut permission durumunu kontrol et
                print("📍 Current permission state: \(locationManager.permissionState)")
                
                if locationManager.needsPermission {
                    // İzin yoksa iste
                    print("📍 Requesting location permission...")
                    await locationManager.requestWhenInUsePermission()
                    
                    // Permission aldıktan sonra location updates otomatik başlayacak (didChangeAuthorization'da)
                    print("📍 Permission request completed, updates will start automatically")
                } else if locationManager.isFullyAuthorized || locationManager.permissionState == .whenInUseGranted {
                    // İzin varsa ama location updates başlamamışsa başlat
                    if locationManager.currentLocation == nil {
                        print("📍 Permission exists but no location yet, starting updates...")
                        locationManager.startLocationUpdates()
                    } else {
                        print("📍 Location already available: \(locationManager.currentLocation!.coordinate)")
                    }
                }
            }
            
            hasInitialized = true
        }
        .onChange(of: locationManager.significantLocationChange) { _, newLocation in
            if let location = newLocation {
                // 1. ExploredCirclesManager - Fog of War için
                exploredCirclesManager.addLocation(location)
                
                // 2. VisitedRegionManager - Database ve achievement için
                visitedRegionManager.processNewLocation(location)
                
                // 3. ReverseGeocoder - Ana sayfa konum bilgisi için
                reverseGeocoder.geocodeLocation(location)
                
                print("🎯 Processing location: \(location.coordinate) - All systems active")
            }
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if let location = newLocation {
                // İlk konum geldiğinde log'la - harita kendi center'layacak
                if !hasInitialized {
                    print("📍 First location update received: \(location.coordinate)")
                }
            }
        }
        } // NavigationStack
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
    @ObservedObject var exploredCirclesManager: ExploredCirclesManager
    @ObservedObject var reverseGeocoder: ReverseGeocoder
    @ObservedObject var gridHashManager: GridHashManager
    @Binding var position: MapCameraPosition
    @Binding var currentZoomLevel: String
    
    // Settings entegrasyonu
    private let settings = AppSettings.shared
    
    private var isLocationTrackingActive: Bool {
        return locationManager.isFullyAuthorized && CLLocationManager.locationServicesEnabled()
    }
    
    private func formatArea(_ area: Double) -> String {
        if area > 1_000_000 {
            return String(format: "%.1f km²", area / 1_000_000)
        } else {
            return String(format: "%.0f m²", area)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // İstatistik Kartı - enableExplorationStats ayarına göre göster
            if settings.enableExplorationStats {
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
                                .onAppear {
                                    print("🎯 BottomControlPanel: Percentage on appear: \(gridHashManager.formattedPercentage)%")
                                }
                                .onChange(of: gridHashManager.formattedPercentage) { _, newValue in
                                    print("🎯 BottomControlPanel: Percentage updated to: \(newValue)%")
                                }
                            
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
                        
                        // Bölge sayısı
                        Text("\(exploredCirclesManager.exploredCircles.count) bölge")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
            }
            
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
