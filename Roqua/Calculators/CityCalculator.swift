import Foundation

// MARK: - City Calculator
struct CityCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        guard let cityName = params?["cityName"] as? String else { 
            print("⚠️ CityCalculator: Missing cityName parameter")
            return 0 
        }
        
        return regions.filter { $0.city?.contains(cityName) == true }.count
    }
} 