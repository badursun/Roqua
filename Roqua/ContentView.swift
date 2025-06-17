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
    @StateObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var position = MapCameraPosition.automatic
    @State private var showingSideMenu = false
    @State private var showingAccount = false
    @State private var showingAchievements = false
    @State private var navigationPath = NavigationPath()
    @State private var hasInitialized = false
    @State private var currentZoomLevel: String = "1:200m"
    @State private var lastPOIDetection: (name: String, category: String)? = nil
    
    private var isLocationTrackingActive: Bool {
        return locationManager.isFullyAuthorized && CLLocationManager.locationServicesEnabled()
    }
    
    // Dynamic colors based on current color scheme (now managed globally)
    private var buttonBackgroundMaterial: Material {
        colorScheme == .dark ? .ultraThinMaterial : .thickMaterial
    }
    
    private var buttonIconColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var overlayBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.3)
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
                                .fill(buttonBackgroundMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(buttonIconColor)
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
                                .fill(buttonBackgroundMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "trophy.fill")
                                .font(.title2)
                                .foregroundStyle(buttonIconColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Konum Durumu Göstergesi
                    LocationStatusIndicator(locationManager: locationManager)
                    
                    Spacer()
                    
                    // Sağ - Settings Butonu
                    Button(action: { 
                        navigationPath.append("settings")
                    }) {
                        ZStack {
                            Circle()
                                .fill(buttonBackgroundMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(buttonIconColor)
                        }
                    }
                    
                    // Spacing between Settings and Menu
                    Spacer()
                        .frame(width: 8)
                    
                    // Hamburger Menu Butonu
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSideMenu = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(buttonBackgroundMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundStyle(buttonIconColor)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // POI Detection Bar
                POIDetectionBar(lastPOIDetection: lastPOIDetection)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                Spacer()
            }
            
            // Bottom Controller Panel
            VStack {
                Spacer()
                
                // Konumum Butonu - Bottom panel üstünde sağ tarafa
                HStack {
                    Spacer()
                    
                    Button(action: {
                        print("🎯 Konumum butonu tıklandı!")
                        FogOfWarMapView.centerToCurrentLocation(locationManager: locationManager)
                    }) {
                        ZStack {
                            Circle()
                                .fill(buttonBackgroundMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: isLocationTrackingActive ? "location.fill" : "location.slash.fill")
                                .font(.title2)
                                .foregroundStyle(isLocationTrackingActive ? buttonIconColor : .red)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }
                
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
            
            // Side Menu Overlay
            if showingSideMenu {
                overlayBackgroundColor
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSideMenu = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(999)
                
                HStack {
                    SideMenuOverlay(
                        isShowing: $showingSideMenu,
                        navigationPath: $navigationPath
                    )
                    .transition(.move(edge: .leading))
                    
                    Spacer()
                }
                .zIndex(1000)
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
                .zIndex(1001)
            }
        }
        .sheet(isPresented: $showingAccount) {
            AccountView()
        }
        .navigationDestination(for: String.self) { destination in
            switch destination {
            case "achievements":
                ModernAchievementPageView()
            case "settings":
                SettingsPageView()
            case "statistics":
                StatisticsView()
            case "about":
                AboutView()
            case "account":
                AccountView()
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
                print("🔥 CONTENTVIEW: Significant location change detected!")
                print("🔥 CONTENTVIEW: Location: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude))")
                
                // Data processing only - no map centering here
                // Map centering is handled by real-time observer in FogOfWarMapView
                
                // 1. ExploredCirclesManager - Fog of War için
                exploredCirclesManager.addLocation(location)
                
                // 2. VisitedRegionManager - Database ve achievement için
                print("🔥 CONTENTVIEW: Calling visitedRegionManager.processNewLocation")
                visitedRegionManager.processNewLocation(location)
                
                // 3. ReverseGeocoder - Ana sayfa konum bilgisi için
                reverseGeocoder.geocodeLocation(location)
                
                print("🎯 Processing location: \(location.coordinate) - Data processing only (auto-centering handled by map observer)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newPOIDiscovered)) { notification in
            if let userInfo = notification.userInfo,
               let name = userInfo["name"] as? String,
               let category = userInfo["category"] as? String {
                print("🔥 CONTENTVIEW: POI detected - \(name) (\(category))")
                lastPOIDetection = (name: name, category: category)
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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(colorScheme == .dark ? .ultraThinMaterial : .thickMaterial)
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
    @Environment(\.colorScheme) private var colorScheme
    
    // Settings entegrasyonu
    private let settings = AppSettings.shared
    
    // POI Debug state
    @StateObject private var visitedRegionManager = VisitedRegionManager.shared
    
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
    
    // POI Detection Status
    private var lastPOIDetection: (name: String, category: String)? {
        guard let lastRegion = visitedRegionManager.visitedRegions.last,
              let poiName = lastRegion.poiName,
              let poiCategory = lastRegion.poiCategory else {
            return nil
        }
        return (name: poiName, category: poiCategory)
    }
    
    var body: some View {
        VStack(spacing: 12) {
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
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
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
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        
                        // Bölge sayısı
                        Text("\(exploredCirclesManager.exploredCircles.count) bölge")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? .ultraThinMaterial : .thickMaterial)
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
            

            
            // Bilgi Çubuğu (Alt kısım) - POI göstergesi eklendi
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
                    .fill(colorScheme == .dark ? .ultraThinMaterial : .thickMaterial)
                    .opacity(0.8)
            )
        }
    }
    

}

// POI Detection Bar Component
struct POIDetectionBar: View {
    let lastPOIDetection: (name: String, category: String)?
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon - Privacy mode veya POI durumuna göre
            if settings.offlineMode {
                Image(systemName: "airplane")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 24, height: 24)
            } else if let poiInfo = lastPOIDetection {
                Image(systemName: poiCategoryIcon(poiInfo.category))
                    .font(.title3)
                    .foregroundStyle(poiCategoryColor(poiInfo.category))
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "location.magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .frame(width: 24, height: 24)
            }
            
            // Information Content
            VStack(alignment: .leading, spacing: 2) {
                if settings.offlineMode {
                    // Çevrimdışı Mod Aktif Mesajı
                    Text("Gizlilik Modu Aktif")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                    
                    Text("Çevrimdışı Çalışıyor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if let poiInfo = lastPOIDetection {
                    Text(poiInfo.name.count > 25 ? String(poiInfo.name.prefix(25)) + "..." : poiInfo.name)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(poiCategoryDisplayName(poiInfo.category))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Konum analiz ediliyor...")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Text("Yakındaki özel yerler aranıyor")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Status Indicator
            if settings.offlineMode {
                Circle()
                    .fill(.orange)
                    .frame(width: 8, height: 8)
            } else if lastPOIDetection != nil {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(.orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.0)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: lastPOIDetection == nil)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(0.9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(settings.offlineMode ? .orange.opacity(0.3) : (lastPOIDetection != nil ? poiCategoryColor(lastPOIDetection!.category).opacity(0.3) : .gray.opacity(0.2)), lineWidth: 1)
        )
    }
    
    // POI kategori ikonları - Tüm MapKit kategorileri
    private func poiCategoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        // Religious sites
        case "mosque": return "moon.stars.fill"
        case "church": return "cross.circle.fill"
        case "synagogue": return "star.of.david.fill"
        case "religioussite": return "building.columns.fill"
        
        // Healthcare
        case "hospital": return "cross.fill"
        case "pharmacy": return "pills.fill"
        
        // Education
        case "school": return "graduationcap.fill"
        case "university": return "graduationcap.fill"
        case "library": return "book.fill"
        
        // Food & Dining
        case "restaurant": return "fork.knife"
        case "cafe": return "cup.and.saucer.fill"
        case "bakery": return "birthday.cake.fill"
        case "brewery": return "cup.and.saucer.fill"
        case "winery": return "wineglass.fill"
        
        // Shopping & Services
        case "store": return "bag.fill"
        case "bank": return "dollarsign.circle.fill"
        case "atm": return "creditcard.fill"
        case "postoffice": return "envelope.fill"
        case "mailbox": return "envelope.fill"
        case "laundry": return "washer.fill"
        case "beauty": return "sparkles"
        
        // Transportation
        case "airport": return "airplane"
        case "airportgate": return "airplane.departure"
        case "airportterminal": return "airplane.arrival"
        case "publictransport": return "bus.fill"
        case "gasstation": return "fuelpump.fill"
        case "evcharger": return "bolt.car.fill"
        case "parking": return "parkingsign"
        case "carrental": return "car.fill"
        
        // Entertainment & Recreation
        case "museum": return "building.columns.fill"
        case "theater": return "theatermasks.fill"
        case "movietheater": return "tv.fill"
        case "amusementpark": return "gamecontroller.fill"
        case "park": return "tree.fill"
        case "nationalpark": return "mountain.2.fill"
        case "playground": return "figure.and.child.holdinghands"
        case "zoo": return "pawprint.fill"
        case "aquarium": return "fish.fill"
        case "beach": return "sun.max.fill"
        
        // Sports & Fitness
        case "fitnescenter": return "figure.run"
        case "golf": return "figure.golf"
        case "tennis": return "tennisball.fill"
        case "basketball": return "basketball.fill"
        case "baseball": return "baseball.fill"
        case "soccer": return "soccerball"
        case "swimming": return "figure.pool.swim"
        case "skiing": return "figure.skiing.downhill"
        case "hiking": return "figure.hiking"
        case "rockclimbing": return "mountain.2.fill"
        case "fishing": return "fish.fill"
        case "surfing": return "figure.surfing"
        case "volleyball": return "volleyball.fill"
        case "bowling": return "bowling.ball"
        case "skating": return "figure.skating"
        case "minigolf": return "figure.golf"
        case "gokart": return "car.fill"
        
        // Accommodation
        case "hotel": return "bed.double.fill"
        case "campground": return "tent.fill"
        case "rvpark": return "car.fill"
        
        // Emergency & Public Services
        case "firestation": return "flame.fill"
        case "police": return "shield.fill"
        case "restroom": return "figure.walk"
        
        // Landmarks & Culture
        case "landmark": return "star.fill"
        case "castle": return "building.columns.fill"
        case "fortress": return "building.columns.fill"
        case "nationalmonument": return "building.columns.fill"
        case "conventionCenter": return "building.fill"
        
        // Other
        case "marina": return "sailboat.fill"
        case "fairground": return "gamecontroller.fill"
        case "distillery": return "drop.fill"
        case "spa": return "leaf.fill"
        case "stadium": return "building.fill"
        case "musicvenue": return "music.note"
        case "nightlife": return "moon.stars.fill"
        case "planetarium": return "globe"
        case "animalservice": return "pawprint.fill"
        case "automotiverepair": return "wrench.fill"
        case "foodmarket": return "cart.fill"
        case "skatepakr": return "figure.skating"
        case "kayaking": return "kayak"
        
        default: return "mappin.circle.fill"
        }
    }
    
    // POI kategori renkleri - Kategoriye göre mantıklı renkler
    private func poiCategoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        // Religious sites - Yeşil tonları
        case "mosque": return .green
        case "church": return .purple
        case "synagogue": return .blue
        case "religioussite": return .indigo
        
        // Healthcare - Kırmızı/Pembe tonları
        case "hospital": return .red
        case "pharmacy": return .mint
        
        // Education - Turuncu tonları
        case "school", "university", "library": return .orange
        
        // Food & Dining - Sarı/Kahverengi tonları
        case "restaurant", "cafe", "bakery", "brewery", "winery": return .yellow
        
        // Shopping & Services - Yeşil tonları
        case "store", "bank", "atm": return .green
        case "postoffice", "mailbox": return .blue
        case "laundry", "beauty": return .pink
        
        // Transportation - Mavi tonları
        case "airport", "airportgate", "airportterminal", "publictransport": return .blue
        case "gasstation", "evcharger", "parking", "carrental": return .cyan
        
        // Entertainment & Recreation - Mor tonları
        case "museum", "theater", "movietheater": return .purple
        case "amusementpark", "zoo", "aquarium": return .pink
        case "park", "nationalpark", "playground", "beach": return .green
        
        // Sports & Fitness - Turuncu/Kırmızı tonları
        case "fitnesscenter", "golf", "tennis", "basketball", "baseball", "soccer": return .orange
        case "swimming", "skiing", "hiking", "rockclimbing", "fishing", "surfing": return .cyan
        case "volleyball", "bowling", "skating", "minigolf", "gokart": return .red
        
        // Accommodation - Kahverengi tonları
        case "hotel", "campground", "rvpark": return .brown
        
        // Emergency & Public Services - Kırmızı tonları
        case "firestation", "police": return .red
        case "restroom": return .gray
        
        // Landmarks & Culture - Altın/Sarı tonları
        case "landmark", "castle", "fortress", "nationalmonument", "conventioncenter": return .yellow
        
        // Other - Karma renkler
        case "marina": return .blue
        case "fairground": return .pink
        case "distillery": return .brown
        case "spa": return .mint
        case "stadium": return .red
        case "musicvenue", "nightlife": return .purple
        case "planetarium": return .indigo
        case "animalservice": return .green
        case "automotiverepair": return .gray
        case "foodmarket": return .orange
        case "skatepark": return .orange
        case "kayaking": return .cyan
        
        default: return .gray
        }
    }
    
    // POI kategori görünen adları - Tüm MapKit kategorileri
    private func poiCategoryDisplayName(_ category: String) -> String {
        switch category.lowercased() {
        // Religious sites
        case "mosque": return "Camii"
        case "church": return "Kilise"
        case "synagogue": return "Sinagog"
        case "religioussite": return "Dini Mekan"
        
        // Healthcare
        case "hospital": return "Hastane"
        case "pharmacy": return "Eczane"
        
        // Education
        case "school": return "Okul"
        case "university": return "Üniversite"
        case "library": return "Kütüphane"
        
        // Food & Dining
        case "restaurant": return "Restoran"
        case "cafe": return "Kafe"
        case "bakery": return "Fırın"
        case "brewery": return "Bira Fabrikası"
        case "winery": return "Şaraphane"
        
        // Shopping & Services
        case "store": return "Mağaza"
        case "bank": return "Banka"
        case "atm": return "ATM"
        case "postoffice": return "Postane"
        case "mailbox": return "Posta Kutusu"
        case "laundry": return "Çamaşırhane"
        case "beauty": return "Güzellik Salonu"
        
        // Transportation
        case "airport": return "Havalimanı"
        case "airportgate": return "Havalimanı Kapısı"
        case "airportterminal": return "Havalimanı Terminali"
        case "publictransport": return "Toplu Taşıma"
        case "gasstation": return "Benzin İstasyonu"
        case "evcharger": return "Elektrikli Araç Şarj"
        case "parking": return "Otopark"
        case "carrental": return "Araç Kiralama"
        
        // Entertainment & Recreation
        case "museum": return "Müze"
        case "theater": return "Tiyatro"
        case "movietheater": return "Sinema"
        case "amusementpark": return "Lunapark"
        case "park": return "Park"
        case "nationalpark": return "Milli Park"
        case "playground": return "Oyun Parkı"
        case "zoo": return "Hayvanat Bahçesi"
        case "aquarium": return "Akvaryum"
        case "beach": return "Plaj"
        
        // Sports & Fitness
        case "fitnesscenter": return "Spor Salonu"
        case "golf": return "Golf Sahası"
        case "tennis": return "Tenis Kortu"
        case "basketball": return "Basketbol Sahası"
        case "baseball": return "Beyzbol Sahası"
        case "soccer": return "Futbol Sahası"
        case "swimming": return "Yüzme Havuzu"
        case "skiing": return "Kayak Pisti"
        case "hiking": return "Yürüyüş Parkuru"
        case "rockclimbing": return "Kaya Tırmanışı"
        case "fishing": return "Balık Tutma"
        case "surfing": return "Sörf"
        case "volleyball": return "Voleybol Sahası"
        case "bowling": return "Bowling"
        case "skating": return "Paten Pisti"
        case "minigolf": return "Mini Golf"
        case "gokart": return "Go-Kart"
        
        // Accommodation
        case "hotel": return "Otel"
        case "campground": return "Kamp Alanı"
        case "rvpark": return "Karavan Parkı"
        
        // Emergency & Public Services
        case "firestation": return "İtfaiye"
        case "police": return "Polis"
        case "restroom": return "Tuvalet"
        
        // Landmarks & Culture
        case "landmark": return "Önemli Yer"
        case "castle": return "Kale"
        case "fortress": return "Hisar"
        case "nationalmonument": return "Milli Anıt"
        case "conventioncenter": return "Kongre Merkezi"
        
        // Other
        case "marina": return "Marina"
        case "fairground": return "Fuar Alanı"
        case "distillery": return "Damıtımevi"
        case "spa": return "Spa"
        case "stadium": return "Stadyum"
        case "musicvenue": return "Müzik Mekanı"
        case "nightlife": return "Gece Hayatı"
        case "planetarium": return "Planetaryum"
        case "animalservice": return "Veteriner"
        case "automotiverepair": return "Oto Tamir"
        case "foodmarket": return "Market"
        case "skatepark": return "Kaykay Parkı"
        case "kayaking": return "Kano"
        
        default: return "Özel Yer"
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
