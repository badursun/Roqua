import Foundation
import CoreLocation
import Combine

@MainActor
class GridHashManager: ObservableObject {
    static let shared = GridHashManager()

    @Published var explorationPercentage: Double = 0.0
    @Published var totalVisitedGrids: Int = 0
    @Published var formattedPercentage: String = "0.00000"
    
    private let settings = AppSettings.shared
    private var visitedGrids: Set<String> = []
    private let storageKey = "visitedGridHashes"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadFromDisk()
        updateExplorationStats()
        setupSettingsObserver()
    }
    
    // MARK: - Settings Observer
    private func setupSettingsObserver() {
        // Settings değişikliklerini dinle
        settings.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateFormattedPercentage()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateFormattedPercentage() {
        formattedPercentage = String(format: "%.\(settings.percentageDecimals)f", explorationPercentage)
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
        updateFormattedPercentage()
    }
    
    private func calculateTotalWorldGrids() -> Double {
        // Keşif radius'una göre grid boyutunu hesapla
        let explorationRadius = settings.explorationRadius
        
        // Grid boyutu = exploration radius'un yarısı (daha gerçekçi)
        let gridSizeMeters = explorationRadius / 2.0
        
        // Metre'yi derece'ye çevir (1° ≈ 111km)
        let gridSizeDegrees = gridSizeMeters / 111_000.0
        
        let latSteps = 180.0 / gridSizeDegrees  // -90° to +90°
        let lonSteps = 360.0 / gridSizeDegrees  // -180° to +180°
        return latSteps * lonSteps
    }

    private func gridHashes(for region: VisitedRegion) -> Set<String> {
        var result = Set<String>()
        let center = CLLocation(latitude: region.latitude, longitude: region.longitude)
        
        // Keşif radius'una göre grid boyutunu hesapla
        let explorationRadius = settings.explorationRadius
        let gridSizeMeters = explorationRadius / 2.0
        let gridSizeDegrees = gridSizeMeters / 111_000.0

        // Region radius'u kadar grid'leri kapsa
        let steps = Int(ceil(Double(region.radius) / gridSizeMeters)) + 1

        for latOffset in -steps...steps {
            for lonOffset in -steps...steps {
                let lat = region.latitude + (Double(latOffset) * gridSizeDegrees)
                let lon = region.longitude + (Double(lonOffset) * gridSizeDegrees)
                let point = CLLocation(latitude: lat, longitude: lon)
                if point.distance(from: center) <= Double(region.radius) {
                    result.insert(hash(for: lat, lon, gridSize: gridSizeDegrees))
                }
            }
        }

        return result
    }

    private func hash(for lat: Double, _ lon: Double, gridSize: Double) -> String {
        let latIndex = Int((lat + 90.0) / gridSize)
        let lonIndex = Int((lon + 180.0) / gridSize)
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
        let explorationRadius = settings.explorationRadius
        let gridSizeMeters = explorationRadius / 2.0
        
        print("🌍 GridHashManager Status:")
        print("   Exploration radius: \(explorationRadius)m")
        print("   Grid size: \(Int(gridSizeMeters))m")
        print("   Total world grids: \(String(format: "%.0f", totalWorldGrids))")
        print("   Visited grids: \(totalVisitedGrids)")
        print("   Exploration: \(getExplorationPercentage())%")
        print("   Sample grids: \(Array(visitedGrids.prefix(3)))")
    }
} 