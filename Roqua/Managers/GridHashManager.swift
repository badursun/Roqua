import Foundation
import CoreLocation

@MainActor
class GridHashManager: ObservableObject {
    static let shared = GridHashManager()

    @Published var explorationPercentage: Double = 0.0
    @Published var totalVisitedGrids: Int = 0
    
    private let settings = AppSettings.shared
    private var visitedGrids: Set<String> = []
    private let storageKey = "visitedGridHashes"

    private init() {
        loadFromDisk()
        updateExplorationStats()
    }

    // MARK: - Public Methods

    func register(region: VisitedRegion) {
        let newHashes = self.gridHashes(for: region)
        let beforeCount = visitedGrids.count
        visitedGrids.formUnion(newHashes)

        if visitedGrids.count > beforeCount {
            saveToDisk()
            updateExplorationStats()
            print("🌍 GridHashManager: Added \(visitedGrids.count - beforeCount) new grids. Total: \(visitedGrids.count)")
        }
    }

    func getExplorationPercentage(decimals: Int? = nil) -> String {
        let decimalPlaces = decimals ?? settings.percentageDecimals
        return String(format: "%.\(decimalPlaces)f", explorationPercentage)
    }
    
    func getExplorationPercentageDouble() -> Double {
        return explorationPercentage
    }

    func exportHashes() -> [String] {
        return Array(visitedGrids)
    }

    func importHashes(from list: [String]) {
        visitedGrids.formUnion(list)
        saveToDisk()
        updateExplorationStats()
    }

    func clearAll() {
        visitedGrids.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        updateExplorationStats()
    }

    // MARK: - Private Methods
    
    private func updateExplorationStats() {
        totalVisitedGrids = visitedGrids.count
        let totalWorldGrids = calculateTotalWorldGrids()
        explorationPercentage = (Double(totalVisitedGrids) / totalWorldGrids) * 100.0
    }
    
    private func calculateTotalWorldGrids() -> Double {
        let resolution = settings.gridResolution
        let latSteps = 180.0 / resolution  // -90° to +90°
        let lonSteps = 360.0 / resolution  // -180° to +180°
        return latSteps * lonSteps
    }

    private func gridHashes(for region: VisitedRegion) -> Set<String> {
        var result = Set<String>()
        let center = CLLocation(latitude: region.latitude, longitude: region.longitude)
        let resolution = settings.gridResolution

        // Hesap: 1° = ~111km
        let stepMeters = resolution * 111_000
        let steps = Int(ceil(Double(region.radius) / stepMeters)) + 1

        for latOffset in -steps...steps {
            for lonOffset in -steps...steps {
                let lat = region.latitude + (Double(latOffset) * resolution)
                let lon = region.longitude + (Double(lonOffset) * resolution)
                let point = CLLocation(latitude: lat, longitude: lon)
                if point.distance(from: center) <= Double(region.radius) {
                    result.insert(hash(for: lat, lon))
                }
            }
        }

        return result
    }

    private func hash(for lat: Double, _ lon: Double) -> String {
        let resolution = settings.gridResolution
        let latIndex = Int((lat + 90.0) / resolution)
        let lonIndex = Int((lon + 180.0) / resolution)
        return "\(latIndex)_\(lonIndex)"
    }

    // MARK: - Persistent Storage

    private func saveToDisk() {
        let array = Array(visitedGrids)
        UserDefaults.standard.set(array, forKey: storageKey)
    }

    private func loadFromDisk() {
        if let saved = UserDefaults.standard.array(forKey: storageKey) as? [String] {
            visitedGrids = Set(saved)
        }
    }
    
    // MARK: - Debug
    func printStatus() {
        let totalWorldGrids = calculateTotalWorldGrids()
        print("🌍 GridHashManager Status:")
        print("   Resolution: \(settings.gridResolution)° (~\(Int(settings.gridResolution * 111_000))m)")
        print("   Total world grids: \(String(format: "%.0f", totalWorldGrids))")
        print("   Visited grids: \(totalVisitedGrids)")
        print("   Exploration: \(getExplorationPercentage())%")
        print("   Sample grids: \(Array(visitedGrids.prefix(3)))")
    }
} 