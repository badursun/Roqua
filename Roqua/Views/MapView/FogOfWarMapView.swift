import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Fog of War Overlay
class FogOfWarOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    let exploredCircles: [CLLocationCoordinate2D]
    let radius: Double
    
    init(exploredCircles: [CLLocationCoordinate2D], radius: Double = 200.0) {
        self.exploredCircles = exploredCircles
        self.radius = radius
        
        // Merkez koordinat olarak ilk circle'ı kullan, yoksa varsayılan
        self.coordinate = exploredCircles.first ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        
        // Tüm dünyayı kaplayan bir rect oluştur
        self.boundingMapRect = MKMapRect.world
        super.init()
    }
}

class FogOfWarRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? FogOfWarOverlay else { return }
        
        let drawRect = rect(for: mapRect)
        
        // Sadece debug gerektiğinde log
        if overlay.exploredCircles.count > 0 && Int(zoomScale * 100) % 50 == 0 { // Zoom değişimlerinde log
            print("🎨 Drawing fog overlay - circles: \(overlay.exploredCircles.count), zoom: \(String(format: "%.2f", zoomScale)), radius: \(Int(overlay.radius))m")
        }
        
        // Fog layer (karanlık katman) - daha koyu görünüm için alpha artırıldı
        context.setFillColor(UIColor.black.withAlphaComponent(0.85).cgColor)
        context.fill(drawRect)
        
        // Keşfedilen alanları temizle (şeffaf yap)
        context.setBlendMode(.clear)
        
        for coordinate in overlay.exploredCircles {
            let point = MKMapPoint(coordinate)
            let pointRect = CGRect(
                x: CGFloat(point.x - mapRect.origin.x) / CGFloat(mapRect.size.width) * drawRect.width + drawRect.origin.x,
                y: CGFloat(point.y - mapRect.origin.y) / CGFloat(mapRect.size.height) * drawRect.height + drawRect.origin.y,
                width: 0,
                height: 0
            )
            
            // DOĞRU RADİUS HESAPLAMASI
            let radiusInMeters = overlay.radius
            
            // Metre'yi derece'ye çevir (latitude'a göre)
            let metersPerMapPoint = MKMapPointsPerMeterAtLatitude(coordinate.latitude)
            let radiusInMapPoints = radiusInMeters * metersPerMapPoint
            
            // Map point'i pixel'e çevir
            let radiusInPixels = CGFloat(radiusInMapPoints) / CGFloat(mapRect.size.width) * drawRect.width
            
            let circleRect = CGRect(
                x: pointRect.origin.x - radiusInPixels,
                y: pointRect.origin.y - radiusInPixels,
                width: radiusInPixels * 2,
                height: radiusInPixels * 2
            )
            
            context.fillEllipse(in: circleRect)
        }
        
        context.setBlendMode(.normal)
    }
}

// ExploredCirclesManager artık ayrı dosyada - Managers/ExploredCirclesManager.swift

// MARK: - Fog of War Map View
struct FogOfWarMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var exploredCirclesManager: ExploredCirclesManager
    @ObservedObject var settings = AppSettings.shared
    @Binding var position: MapCameraPosition
    @Binding var currentZoomLevel: String
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Map type from settings
        switch settings.mapType {
        case 1:
            mapView.mapType = .satellite
        case 2:
            mapView.mapType = .hybrid
        default:
            mapView.mapType = .standard
        }
        
        mapView.showsUserLocation = settings.showUserLocation
        mapView.userTrackingMode = .none // Manuel kontrol - otomatik tracking kapatılıyor
        
        // Zoom ve pan kontrollerini settings'den al
        mapView.isZoomEnabled = !settings.preserveZoomPan // Ters mantık: preserve=true ise zoom disable
        mapView.isPitchEnabled = settings.enablePitch
        mapView.isRotateEnabled = settings.enableRotation
        mapView.isScrollEnabled = !settings.preserveZoomPan // Ters mantık: preserve=true ise scroll disable
        
        // Standard map configuration - POI'leri kaldır (PRD: sade, yazısız, ikon barındırmayan görünüm)
        let config = MKStandardMapConfiguration()
        config.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
        config.showsTraffic = false // Trafik bilgilerini kapat
        mapView.preferredConfiguration = config
        
        // PRD: "şu anki konum" sade bir dot ile gösterilir
        mapView.showsUserLocation = true
        // userLocationDisplayType property'si mevcut değil - default dot zaten
        
        print("🗺️ MapView created with settings: mapType=\(settings.mapType), pitch=\(settings.enablePitch), rotation=\(settings.enableRotation)")
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Settings değişikliklerini uygula
        updateMapSettings(mapView: mapView)
        
        // MapView reference'ı sakla - SIKIK BUTON İÇİN
        context.coordinator.mapView = mapView
        FogOfWarMapView.activeMapView = mapView
        
        // Position binding'i handle et (Konumum butonu için)
        handlePositionBinding(mapView: mapView, context: context)
        
        // Real-time location observer setup (sadece bir kez)
        if !context.coordinator.hasSetupLocationObserver {
            setupLocationObserver(mapView: mapView, context: context)
            context.coordinator.hasSetupLocationObserver = true
        }
        
        // İlk overlay'i ekle (konum olmasaymış gibi)
        if !context.coordinator.hasSetInitialOverlay {
            context.coordinator.addInitialOverlay(mapView: mapView)
            context.coordinator.hasSetInitialOverlay = true
        }
        
        // İlk konum set'i - manual olarak tetiklenir
        // Initial region setting artık location observer'da yapılacak
        
        // Real-time location tracking artık observer ile yapılıyor
        if let currentLocation = locationManager.currentLocation {
            // ExploredCirclesManager'a konum ekle (ContentView'da da ekleniyor ama burada da olsun)
            exploredCirclesManager.addLocation(currentLocation)
            
            // Koordinat sayısı değiştiyse overlay'i güncelle
            let coordinates = exploredCirclesManager.exploredCircles
            
            if coordinates.count != context.coordinator.lastKnownCircleCount {
                context.coordinator.lastKnownCircleCount = coordinates.count
                
                // Overlay'i güncelle - settings'den radius al
                mapView.removeOverlays(mapView.overlays)
                
                // Eğer koordinat yoksa (clearAllData sonrası) overlay ekleme
                if coordinates.isEmpty {
                    print("🗑️ Fog of War cleared - no overlays added")
                } else {
                    let overlay = FogOfWarOverlay(exploredCircles: coordinates, radius: settings.explorationRadius)
                    mapView.addOverlay(overlay)
                    
                    // Sadece önemli değişikliklerde log
                    if coordinates.count % 10 == 0 || coordinates.count < 10 {
                        print("🗺️ Overlay updated - circles: \(coordinates.count), radius: \(Int(settings.explorationRadius))m")
                    }
                }
            }
        }
    }
    
    private func updateMapSettings(mapView: MKMapView) {
        // Map type
        let newMapType: MKMapType
        switch settings.mapType {
        case 1:
            newMapType = .satellite
        case 2:
            newMapType = .hybrid
        default:
            newMapType = .standard
        }
        
        if mapView.mapType != newMapType {
            mapView.mapType = newMapType
        }
        
        // User location
        if mapView.showsUserLocation != settings.showUserLocation {
            mapView.showsUserLocation = settings.showUserLocation
        }
        
        // Interaction settings
        if mapView.isZoomEnabled != !settings.preserveZoomPan {
            mapView.isZoomEnabled = !settings.preserveZoomPan
        }
        
        if mapView.isScrollEnabled != !settings.preserveZoomPan {
            mapView.isScrollEnabled = !settings.preserveZoomPan
        }
        
        if mapView.isPitchEnabled != settings.enablePitch {
            mapView.isPitchEnabled = settings.enablePitch
        }
        
        if mapView.isRotateEnabled != settings.enableRotation {
            mapView.isRotateEnabled = settings.enableRotation
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // SIKIK BUTON İÇİN - Static MapView Manager
    static var activeMapView: MKMapView?
    
    // SIKIK BUTONUN DİREKT ÇAĞIRACAĞI FONKSİYON
    static func centerToCurrentLocation(locationManager: LocationManager) {
        guard let mapView = activeMapView,
              let currentLocation = locationManager.currentLocation else {
            print("❌ SIKIK BUTON: MapView ya da location yok")
            return
        }
        
        let region = MKCoordinateRegion(
            center: currentLocation.coordinate, // Gerçek konum kullan
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )
        
        DispatchQueue.main.async {
            mapView.setRegion(region, animated: true)
            print("🎯 SIKIK BUTON ÇALIŞTI: \(currentLocation.coordinate) (REAL LOCATION)")
        }
    }
    
    // Position binding handler (Konumum butonu için)
    private func handlePositionBinding(mapView: MKMapView, context: Context) {
        // Mirror reflection ile position'dan region extract et
        let mirror = Mirror(reflecting: position)
        for child in mirror.children {
            if let region = child.value as? MKCoordinateRegion {
                let currentCenter = mapView.region.center
                let targetCenter = region.center
                
                // Anlamlı bir fark varsa haritayı güncelle
                let latDiff = abs(currentCenter.latitude - targetCenter.latitude)
                let lonDiff = abs(currentCenter.longitude - targetCenter.longitude)
                
                if latDiff > 0.0001 || lonDiff > 0.0001 {
                    mapView.setRegion(region, animated: true)
                    print("🎯 Map centered via position binding to: \(targetCenter)")
                }
                break
            }
        }
    }
    
    // Real-time location observer setup
    private func setupLocationObserver(mapView: MKMapView, context: Context) {
        let coordinator = context.coordinator
        
        // ÖNEMLİ: Observer başlamadan önce fresh location iste
        Task { @MainActor in
            locationManager.requestFreshLocation()
        }
        
        // LocationManager'dan gelen her location update'ini dinle
        coordinator.locationObserverCancellable = locationManager.$currentLocation
            .compactMap { $0 } // nil locations'ları filtrele
            .filter { location in
                // ÇÖZÜM: Sadece reasonable accuracy'li location'ları kabul et
                let accuracyThreshold: Double = 100.0 // İlk açılış için relaxed threshold
                let isAccurate = location.horizontalAccuracy > 0 && location.horizontalAccuracy <= accuracyThreshold
                if !isAccurate {
                    print("🚫 OBSERVER: Location filtered out - accuracy: \(location.horizontalAccuracy)m > \(accuracyThreshold)m")
                }
                return isAccurate
            }
            .removeDuplicates { old, new in
                // Aynı koordinat tekrar gelirse ignore et (1m hassasiyet)
                let distance = CLLocation(latitude: old.coordinate.latitude, longitude: old.coordinate.longitude)
                    .distance(from: CLLocation(latitude: new.coordinate.latitude, longitude: new.coordinate.longitude))
                return distance < 1.0
            }
            .sink { newLocation in
                // Main thread'de auto-centering yap
                DispatchQueue.main.async {
                    print("🔥 OBSERVER: New location received - \(newLocation.coordinate) (accuracy: \(newLocation.horizontalAccuracy)m)")
                    self.performRealTimeAutoCentering(
                        mapView: mapView,
                        newLocation: newLocation,
                        context: coordinator
                    )
                }
            }
        
        print("🎯 Real-time location observer setup completed")
        print("🔄 Fresh location requested - waiting for update...")
    }
    
    // Her location update'inde auto-centering
    private func performRealTimeAutoCentering(mapView: MKMapView, newLocation: CLLocation, context: Coordinator) {
        let currentMapCenter = mapView.region.center
        let newLocationCoord = newLocation.coordinate
        
        // ÖNEMLİ: İlk konum update'inde ZORLA center'la (setting'lerden bağımsız)
        if !context.hasSetInitialRegion {
            let initialRegion = MKCoordinateRegion(
                center: newLocationCoord, // Gerçek konum kullan
                latitudinalMeters: 200, // Yakın zoom seviyesi
                longitudinalMeters: 200
            )
            mapView.setRegion(initialRegion, animated: false) // İlk set animasyonsuz
            context.hasSetInitialRegion = true
            context.lastKnownLocation = newLocationCoord
            print("🗺️ INITIAL CENTERING: First location received - \(newLocationCoord) (REAL LOCATION)")
            return
        }
        
        // Sonraki auto-centering'ler için setting kontrolü
        guard settings.showUserLocation && settings.autoMapCentering else { 
            print("🚫 Auto-centering disabled in settings")
            return 
        }
        
        // Pin'in ekran merkezi'nden uzaklığını hesapla
        let distanceFromCenter = CLLocation(latitude: currentMapCenter.latitude, longitude: currentMapCenter.longitude)
            .distance(from: newLocation)
        
        // Pin ekran merkezi'nden 10m uzaklaştıysa zorla center'la
        if distanceFromCenter > 10.0 {
            let currentRegion = mapView.region
            let newRegion = MKCoordinateRegion(
                center: newLocationCoord,
                span: currentRegion.span
            )
            
            mapView.setRegion(newRegion, animated: true)
            context.lastKnownLocation = newLocationCoord
            print("🎯 Real-time auto-centering: Pin moved \(Int(distanceFromCenter))m from center")
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: FogOfWarMapView
        var fogOverlay: FogOfWarOverlay?
        var hasSetInitialRegion: Bool = false
        var hasSetInitialOverlay: Bool = false
        var lastKnownCircleCount: Int = 0
        var lastKnownLocation: CLLocationCoordinate2D?
        var hasSetupLocationObserver: Bool = false
        var locationObserverCancellable: AnyCancellable?
        
        // MKMapView reference - SIKIK BUTON İÇİN
        weak var mapView: MKMapView?
        
        init(_ parent: FogOfWarMapView) {
            self.parent = parent
        }
        
        func addInitialOverlay(mapView: MKMapView) {
            // İlk overlay'i ekle - settings'den radius al
            let newOverlay = FogOfWarOverlay(exploredCircles: [], radius: parent.settings.explorationRadius)
            fogOverlay = newOverlay
            mapView.addOverlay(newOverlay)
            print("🗺️ Initial fog overlay added with radius: \(Int(parent.settings.explorationRadius))m")
        }
        
        func updateOverlay(mapView: MKMapView, exploredCircles: [CLLocationCoordinate2D]) {
            // Overlay'i kaldırmak yerine sadece yeniden çizdir
            if let existingOverlay = fogOverlay {
                // Renderer'ı yeniden çizmeye zorla
                DispatchQueue.main.async {
                    mapView.removeOverlay(existingOverlay)
                    mapView.addOverlay(existingOverlay)
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let fogOverlay = overlay as? FogOfWarOverlay {
                // Koordinatlar zaten overlay içinde mevcut, renderer'a geçir
                return FogOfWarRenderer(overlay: fogOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // MARK: - Zoom Tracking
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Zoom seviyesini hesapla ve güncelle
            let region = mapView.region
            let span = region.span
            
            // Latitude span'dan yaklaşık zoom seviyesini hesapla
            let _ = calculateZoomLevel(from: span.latitudeDelta)
            let distanceText = formatZoomDistance(from: span.latitudeDelta)
            
            DispatchQueue.main.async {
                self.parent.currentZoomLevel = distanceText
            }
        }
        
        private func calculateZoomLevel(from latitudeDelta: Double) -> Int {
            // Latitude delta'dan zoom seviyesini hesapla (yaklaşık)
            let zoomLevel = log2(360.0 / latitudeDelta)
            return max(1, min(20, Int(zoomLevel)))
        }
        
        private func formatZoomDistance(from latitudeDelta: Double) -> String {
            // Latitude delta'dan yaklaşık mesafeyi hesapla
            let metersPerDegree = 111000.0 // Yaklaşık 1 derece = 111km
            let approximateDistance = latitudeDelta * metersPerDegree
            
            if approximateDistance < 1000 {
                return "1:\(Int(approximateDistance))m"
            } else if approximateDistance < 10000 {
                return "1:\(String(format: "%.1f", approximateDistance / 1000))km"
            } else {
                return "1:\(Int(approximateDistance / 1000))km"
            }
        }
    }
} 