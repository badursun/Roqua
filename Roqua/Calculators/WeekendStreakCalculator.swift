import Foundation

// MARK: - Weekend Streak Calculator
struct WeekendStreakCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let calendar = Calendar.current
        
        // Filter weekend regions (Saturday = 7, Sunday = 1)
        let weekendRegions = regions.filter { region in
            let weekday = calendar.component(.weekday, from: region.timestampStart)
            return weekday == 1 || weekday == 7
        }
        
        guard !weekendRegions.isEmpty else { return 0 }
        
        // Group by weekend (week of year)
        let weekendDates = Set(weekendRegions.map { 
            calendar.dateInterval(of: .weekOfYear, for: $0.timestampStart)?.start 
        }.compactMap { $0 })
        
        let sortedWeekends = weekendDates.sorted()
        
        guard !sortedWeekends.isEmpty else { return 0 }
        
        var longestStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedWeekends.count {
            let previousWeekend = sortedWeekends[i - 1]
            let currentWeekend = sortedWeekends[i]
            
            let weeksDiff = calendar.dateComponents([.weekOfYear], from: previousWeekend, to: currentWeekend).weekOfYear ?? 0
            
            if weeksDiff == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
} 