import Foundation

// MARK: - Percentage Calculator
struct PercentageCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let multiplier = params?["multiplier"] as? Int ?? 1000
        
        // Get real percentage from GridHashManager (MainActor safe)
        let percentage = MainActor.assumeIsolated {
            return GridHashManager.shared.explorationPercentage
        }
        
        return Int(percentage * Double(multiplier))
    }
} 