import SwiftUI
import MapKit
import CoreLocation

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
    let circleRadius: Double
    
    init(overlay: FogOfWarOverlay, exploredCircles: [CLLocationCoordinate2D], radius: Double = 200.0) {
        self.exploredCircles = exploredCircles
        self.circleRadius = radius
        super.init(overlay: overlay)
        print("🎨 FogOfWarRenderer created with \(exploredCircles.count) explored circles, radius: \(radius)m")
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
                    
                    // Zoom seviyesine göre dinamik radius hesaplama
                    let metersPerMapPoint = MKMapPointsPerMeterAtLatitude(circleCenter.latitude)
                    let radiusInMapPoints = circleRadius * metersPerMapPoint
                    let radiusInPoints = radiusInMapPoints * zoomScale
                    
                    // Zoom seviyesine göre minimum radius ayarı
                    let zoomFactor = max(0.1, min(10.0, zoomScale))
                    let dynamicMinRadius = max(8.0, 15.0 * zoomFactor) // Zoom-in'de daha büyük minimum
                    let dynamicMaxRadius = min(2000.0, 500.0 / zoomFactor) // Zoom-out'ta daha büyük maksimum
                    
                    let finalRadius = max(dynamicMinRadius, min(dynamicMaxRadius, radiusInPoints))
                    
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

// ExploredCirclesManager artık ayrı dosyada - Managers/ExploredCirclesManager.swift

// MARK: - Fog of War Map View
struct FogOfWarMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var exploredCirclesManager: ExploredCirclesManager
    @ObservedObject var visitedRegionManager: VisitedRegionManager
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
        mapView.userTrackingMode = .none // Kullanıcı takibini kapat - zoom sorununa neden oluyor
        
        // Zoom ve pan kontrollerini settings'den al
        mapView.isZoomEnabled = !settings.preserveZoomPan // Ters mantık: preserve=true ise zoom disable
        mapView.isPitchEnabled = settings.enablePitch
        mapView.isRotateEnabled = settings.enableRotation
        mapView.isScrollEnabled = !settings.preserveZoomPan // Ters mantık: preserve=true ise scroll disable
        
        // Standard map configuration - POI'leri kaldır
        let config = MKStandardMapConfiguration()
        config.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
        mapView.preferredConfiguration = config
        
        print("🗺️ MapView created with settings: mapType=\(settings.mapType), pitch=\(settings.enablePitch), rotation=\(settings.enableRotation)")
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Settings değişikliklerini uygula
        updateMapSettings(mapView: mapView)
        
        // İlk konum set'i - sadece bir kez yapılır
        if let currentLocation = locationManager.currentLocation, !context.coordinator.hasSetInitialRegion {
            let region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 200, // Çok daha yakın zoom seviyesi
                longitudinalMeters: 200
            )
            mapView.setRegion(region, animated: false) // İlk set animasyonsuz
            context.coordinator.hasSetInitialRegion = true
            context.coordinator.lastKnownLocation = currentLocation.coordinate
            print("🗺️ Initial map region set to user location")
            
            // İlk overlay'i ekle
            context.coordinator.addInitialOverlay(mapView: mapView)
        }
        
        // Yeni konumu hem ExploredCircles hem de VisitedRegionManager'a ekle
        if let currentLocation = locationManager.currentLocation {
            let oldCount = context.coordinator.lastKnownCircleCount
            let newCoordinate = currentLocation.coordinate
            
            // Konum değişimi kontrolü - settings'den tracking distance al
            if let lastLocation = context.coordinator.lastKnownLocation {
                let distance = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
                    .distance(from: currentLocation)
                
                // Settings'den tracking distance'ı al ve auto centering kontrol et
                if distance > settings.locationTrackingDistance && settings.autoMapCentering {
                    let currentRegion = mapView.region
                    let newRegion = MKCoordinateRegion(
                        center: newCoordinate,
                        span: currentRegion.span // Mevcut zoom seviyesini koru
                    )
                    mapView.setRegion(newRegion, animated: true)
                    context.coordinator.lastKnownLocation = newCoordinate
                    print("🗺️ Map centered to new location - distance moved: \(Int(distance))m (threshold: \(Int(settings.locationTrackingDistance))m)")
                }
            }
            
            exploredCirclesManager.addLocation(currentLocation)
            visitedRegionManager.processNewLocation(currentLocation)
            
            // Koordinat sayısı değiştiyse overlay'i güncelle
            let coordinates = visitedRegionManager.visitedRegions.isEmpty ? 
                exploredCirclesManager.exploredCircles : 
                visitedRegionManager.getCoordinatesForFogOfWar()
            
            if coordinates.count != oldCount {
                context.coordinator.updateOverlay(mapView: mapView, exploredCircles: coordinates)
                context.coordinator.lastKnownCircleCount = coordinates.count
                print("🗺️ Overlay updated - new circle count: \(coordinates.count)")
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
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: FogOfWarMapView
        private var fogOverlay: FogOfWarOverlay?
        var hasSetInitialRegion: Bool = false
        var lastKnownCircleCount: Int = 0
        var lastKnownLocation: CLLocationCoordinate2D?
        
        init(_ parent: FogOfWarMapView) {
            self.parent = parent
        }
        
        func addInitialOverlay(mapView: MKMapView) {
            // İlk overlay'i ekle
            let newOverlay = FogOfWarOverlay(center: CLLocationCoordinate2D(latitude: 0, longitude: 0))
            fogOverlay = newOverlay
            mapView.addOverlay(newOverlay)
            print("🗺️ Initial fog overlay added")
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
                // Koordinatları VisitedRegionManager'dan al, fallback olarak ExploredCircles kullan
                let coordinates = parent.visitedRegionManager.visitedRegions.isEmpty ? 
                    parent.exploredCirclesManager.exploredCircles : 
                    parent.visitedRegionManager.getCoordinatesForFogOfWar()
                
                // Settings'den exploration radius'u al
                let radius = parent.settings.explorationRadius
                
                return FogOfWarRenderer(overlay: fogOverlay, exploredCircles: coordinates, radius: radius)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // MARK: - Zoom Tracking
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Zoom seviyesini hesapla ve güncelle
            let region = mapView.region
            let span = region.span
            
            // Latitude span'dan yaklaşık zoom seviyesini hesapla
            let zoomLevel = calculateZoomLevel(from: span.latitudeDelta)
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