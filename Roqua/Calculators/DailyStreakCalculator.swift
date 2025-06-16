import Foundation

// MARK: - Daily Streak Calculator
struct DailyStreakCalculator: AchievementCalculator {
    func calculate(regions: [VisitedRegion], params: [String: Any]?) -> Int {
        let calendar = Calendar.current
        let sortedRegions = regions.sorted { $0.timestampStart < $1.timestampStart }
        
        guard !sortedRegions.isEmpty else { return 0 }
        
        var longestStreak = 0
        var currentStreak = 0
        var previousDate: Date?
        
        for region in sortedRegions {
            let currentDate = calendar.startOfDay(for: region.timestampStart)
            
            if let prevDate = previousDate {
                let daysDiff = calendar.dateComponents([.day], from: prevDate, to: currentDate).day ?? 0
                
                if daysDiff == 1 {
                    currentStreak += 1
                } else if daysDiff > 1 {
                    currentStreak = 1
                }
                // If daysDiff == 0, same day, don't change streak
            } else {
                currentStreak = 1
            }
            
            longestStreak = max(longestStreak, currentStreak)
            previousDate = currentDate
        }
        
        return longestStreak
    }
} 