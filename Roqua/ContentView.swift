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
    @State private var position = MapCameraPosition.automatic
    @State private var showingSettings = false
    @State private var showingAccount = false
    
    private var isLocationTrackingActive: Bool {
        return locationManager.isFullyAuthorized && CLLocationManager.locationServicesEnabled()
    }
    
    var body: some View {
        ZStack {
            // Tam Ekran Harita
            FogOfWarMapView(
                locationManager: locationManager,
                exploredCirclesManager: exploredCirclesManager,
                position: $position
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
                    if isLocationTrackingActive && locationManager.currentLocation != nil {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            // position güncelleme kodu buraya gelecek
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
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
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
    
    private var isLocationTrackingActive: Bool {
        return locationManager.isFullyAuthorized && CLLocationManager.locationServicesEnabled()
    }
    
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
                                Task {
                                    await locationManager.requestAlwaysPermission()
                                }
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
                            
                            Text(isLocationTrackingActive ? "Aktif" : "Pasif")
                                .foregroundStyle(isLocationTrackingActive ? .green : .red)
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

// MARK: - Fog of War Overlay
class FogOfWarOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    
    init(center: CLLocationCoordinate2D) {
        self.coordinate = center
        
        // Tüm dünyayı kaplayan bir rect oluştur
        self.boundingMapRect = MKMapRect.world
        super.init()
    }
}

class FogOfWarRenderer: MKOverlayRenderer {
    let exploredCircles: [CLLocationCoordinate2D]
    let circleRadius: Double = 200.0 // 200 metre (PRD'ye göre)
    
    init(overlay: FogOfWarOverlay, exploredCircles: [CLLocationCoordinate2D]) {
        self.exploredCircles = exploredCircles
        super.init(overlay: overlay)
        print("🎨 FogOfWarRenderer created with \(exploredCircles.count) explored circles")
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let drawRect = rect(for: mapRect)
        print("🎨 Drawing fog overlay. MapRect: \(mapRect), DrawRect: \(drawRect), ZoomScale: \(zoomScale)")
        print("🎨 Explored circles count: \(exploredCircles.count)")
        
        // Önce tüm alanı karanlık yap
        context.setFillColor(UIColor.black.withAlphaComponent(0.85).cgColor)
        context.fill(drawRect)
        
        // Keşfedilen alanları temizle (clear blend mode ile)
        if !exploredCircles.isEmpty {
            context.setBlendMode(.clear)
            
            for circleCenter in exploredCircles {
                let mapPoint = MKMapPoint(circleCenter)
                
                // Sadece görünür alandaki circle'ları çiz
                if mapRect.intersects(MKMapRect(
                    origin: MKMapPoint(x: mapPoint.x - 1000, y: mapPoint.y - 1000),
                    size: MKMapSize(width: 2000, height: 2000)
                )) {
                    let circlePoint = point(for: mapPoint)
                    
                    // Doğru radius hesaplama - zoom ile birlikte büyür/küçülür
                    let metersPerMapPoint = MKMapPointsPerMeterAtLatitude(circleCenter.latitude)
                    let radiusInMapPoints = circleRadius * metersPerMapPoint
                    let radiusInPoints = radiusInMapPoints * zoomScale
                    
                    // Minimum ve maksimum radius sınırları
                    let minRadius: CGFloat = 5.0
                    let maxRadius: CGFloat = 500.0
                    let finalRadius = max(minRadius, min(maxRadius, radiusInPoints))
                    
                    let circleRect = CGRect(
                        x: circlePoint.x - finalRadius,
                        y: circlePoint.y - finalRadius,
                        width: finalRadius * 2,
                        height: finalRadius * 2
                    )
                    
                    // Circle çiz (keşfedilen alanı temizle)
                    context.fillEllipse(in: circleRect)
                    
                    print("🎨 Drew circle at (\(circlePoint.x), \(circlePoint.y)) with radius \(finalRadius)")
                }
            }
            
            // Blend mode'u normale döndür
            context.setBlendMode(.normal)
        }
    }
}

// MARK: - Explored Circles Manager
class ExploredCirclesManager: ObservableObject {
    @Published var exploredCircles: [CLLocationCoordinate2D] = []
    private let minimumDistance: Double = 10.0 // 10 metre minimum mesafe - daha sık circle
    
    init() {
        print("🎯 ExploredCirclesManager initialized")
    }
    
    func addLocation(_ location: CLLocation) {
        let newCoordinate = location.coordinate
        
        // Çok yakın bir konum varsa ekleme
        for existingCoordinate in exploredCircles {
            let existingLocation = CLLocation(latitude: existingCoordinate.latitude, longitude: existingCoordinate.longitude)
            if location.distance(from: existingLocation) < minimumDistance {
                return
            }
        }
        
        // Yeni konumu ekle
        DispatchQueue.main.async {
            self.exploredCircles.append(newCoordinate)
            print("🎯 New explored area added: \(newCoordinate.latitude), \(newCoordinate.longitude)")
            print("📊 Total explored areas: \(self.exploredCircles.count)")
        }
    }
}

// MARK: - Fog of War Map View
struct FogOfWarMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var exploredCirclesManager: ExploredCirclesManager
    @Binding var position: MapCameraPosition
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow // Kullanıcıyı takip et
        
        // Zoom ve pan kontrollerini etkinleştir
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isScrollEnabled = true
        
        // Standard map configuration
        mapView.preferredConfiguration = MKStandardMapConfiguration()
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Konum güncellendiğinde overlay'i yenile
        context.coordinator.updateOverlay(mapView: mapView, exploredCircles: exploredCirclesManager.exploredCircles)
        
        // İlk konum set'i - sadece bir kez yapılır
        if let currentLocation = locationManager.currentLocation, !context.coordinator.hasSetInitialRegion {
            let region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 1500, // Biraz daha yakın başlangıç
                longitudinalMeters: 1500
            )
            mapView.setRegion(region, animated: false) // İlk set animasyonsuz
            context.coordinator.hasSetInitialRegion = true
            print("🗺️ Initial map region set to user location")
        }
        
        // Yeni konumu explored circles'a ekle (her konum güncellemesinde)
        if let currentLocation = locationManager.currentLocation {
            exploredCirclesManager.addLocation(currentLocation)
            
            // Haritayı kullanıcı konumuna ortalamaya devam et (yumuşak geçiş)
            if context.coordinator.hasSetInitialRegion {
                let currentRegion = mapView.region
                let newRegion = MKCoordinateRegion(
                    center: currentLocation.coordinate,
                    span: currentRegion.span // Mevcut zoom seviyesini koru
                )
                mapView.setRegion(newRegion, animated: true) // Yumuşak geçiş
                print("🗺️ Map centered to user location: \(currentLocation.coordinate)")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: FogOfWarMapView
        private var fogOverlay: FogOfWarOverlay?
        var hasSetInitialRegion: Bool = false
        
        init(_ parent: FogOfWarMapView) {
            self.parent = parent
        }
        
        func updateOverlay(mapView: MKMapView, exploredCircles: [CLLocationCoordinate2D]) {
            // Eski overlay'i kaldır
            if let existingOverlay = fogOverlay {
                mapView.removeOverlay(existingOverlay)
            }
            
            // Yeni overlay ekle
            let newOverlay = FogOfWarOverlay(center: CLLocationCoordinate2D(latitude: 0, longitude: 0))
            fogOverlay = newOverlay
            mapView.addOverlay(newOverlay)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let fogOverlay = overlay as? FogOfWarOverlay {
                return FogOfWarRenderer(overlay: fogOverlay, exploredCircles: parent.exploredCirclesManager.exploredCircles)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#Preview {
    ContentView()
}
