import Foundation

// MARK: - Country Calculator
struct CountryCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let uniqueCountries = Set(regions.compactMap { $0.country })
        return uniqueCountries.count
    }
} 