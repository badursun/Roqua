import Foundation
import CoreLocation

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