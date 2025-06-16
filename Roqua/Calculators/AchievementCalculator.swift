import Foundation

// MARK: - Achievement Calculator Protocol
protocol AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int
}

// MARK: - Calculator Factory
class CalculatorFactory {
    static func getCalculator(for type: String) -> AchievementCalculator {
        switch type {
        // Basic Calculators
        case "milestone": return MilestoneCalculator()
        case "city": return CityCalculator()
        case "district": return DistrictCalculator()
        case "country": return CountryCalculator()
        case "area": return AreaCalculator()
        case "percentage": return PercentageCalculator()
        
        // Advanced Calculators
        case "daily_streak": return DailyStreakCalculator()
        case "weekend_streak": return WeekendStreakCalculator()
        
        // Default fallback
        default: return DefaultCalculator()
        }
    }
}

// MARK: - Default Calculator
struct DefaultCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        print("⚠️ Unknown calculator type, returning 0")
        return 0
    }
} 