import Foundation

// MARK: - District Calculator
struct DistrictCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let uniqueDistricts = Set(regions.compactMap { $0.district })
        return uniqueDistricts.count
    }
} 