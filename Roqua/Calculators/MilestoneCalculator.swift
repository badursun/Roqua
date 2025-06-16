import Foundation

// MARK: - Milestone Calculator
struct MilestoneCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        return regions.count
    }
} 