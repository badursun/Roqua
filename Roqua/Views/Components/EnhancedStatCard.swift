import SwiftUI

// MARK: - Enhanced Stat Card (Premium Design)
struct EnhancedStatCard: View {
    let value: String
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let isHighlighted: Bool
    
    init(value: String, title: String, subtitle: String? = nil, icon: String, color: Color, isHighlighted: Bool = false) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Premium Icon with enhanced glow
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(isHighlighted ? 0.5 : 0.3),
                                color.opacity(isHighlighted ? 0.2 : 0.1),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 16
                        )
                    )
                    .frame(width: 32, height: 32)
                    .blur(radius: 1)
                
                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.8),
                                color.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
            }
            .scaleEffect(isHighlighted ? 1.05 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isHighlighted)
            
            // Value with enhanced styling
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: isHighlighted ? 
                            [.white, color.opacity(0.9)] : 
                            [.white, .white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            // Title
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            // Subtitle (optional)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            } else {
                // Placeholder to maintain consistent spacing
                Text(" ")
                    .font(.system(size: 8))
                    .foregroundColor(.clear)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 75) // Fixed height for all cards
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: isHighlighted ? 
                                    [color.opacity(0.5), color.opacity(0.2)] :
                                    [color.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isHighlighted ? 2 : 1
                        )
                )
                .shadow(
                    color: isHighlighted ? color.opacity(0.4) : .black.opacity(0.1),
                    radius: isHighlighted ? 6 : 2,
                    x: 0,
                    y: isHighlighted ? 4 : 2
                )
        )
    }
}

// MARK: - Achievement Statistics Helper
extension AchievementManager {
    
    // MARK: - Streak Calculation
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all unlocked achievements sorted by date
        let unlockedAchievements = achievements.compactMap { achievement in
            if let progress = getProgress(for: achievement.id),
               progress.isUnlocked,
               let unlockedDate = progress.unlockedAt {
                return calendar.startOfDay(for: unlockedDate)
            }
            return nil
        }.sorted(by: >)
        
        guard !unlockedAchievements.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = today
        
        // Check for consecutive days
        for unlockedDate in unlockedAchievements {
            if calendar.isDate(unlockedDate, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if unlockedDate < currentDate {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Monthly Progress
    var monthlyUnlockedCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return achievements.filter { achievement in
            if let progress = getProgress(for: achievement.id),
               progress.isUnlocked,
               let unlockedDate = progress.unlockedAt {
                return unlockedDate >= startOfMonth
            }
            return false
        }.count
    }
    
    // MARK: - Point System (Rarity-based)
    var totalPoints: Int {
        return achievements.reduce(0) { total, achievement in
            if let progress = getProgress(for: achievement.id), progress.isUnlocked {
                switch achievement.rarity {
                case .common: return total + 1
                case .rare: return total + 3
                case .epic: return total + 5
                case .legendary: return total + 10
                }
            }
            return total
        }
    }
    
    // MARK: - Next Milestone
    var nextMilestone: (target: Int, current: Int, name: String) {
        let milestones = [
            (5, "İlk Adım"),
            (10, "Yükseliş"),
            (25, "Usta"),
            (50, "Efsane"),
            (75, "Kahraman"),
            (100, "Ölümsüz")
        ]
        
        let currentCount = totalUnlockedCount
        
        for milestone in milestones {
            if currentCount < milestone.0 {
                return (milestone.0, currentCount, milestone.1)
            }
        }
        
        // If all milestones completed
        return (100, currentCount, "Tamamlandı")
    }
}

// MARK: - Preview
struct EnhancedStatCard_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 8) {
            EnhancedStatCard(
                value: "7",
                title: "Günlük Seri",
                subtitle: "🔥 Rekor!",
                icon: "flame.fill",
                color: .orange,
                isHighlighted: true
            )
            
            EnhancedStatCard(
                value: "12",
                title: "Bu Ay",
                icon: "calendar.badge.plus",
                color: .green
            )
            
            EnhancedStatCard(
                value: "245",
                title: "Toplam Puan",
                subtitle: "Epic seviye",
                icon: "star.circle.fill",
                color: .purple
            )
            
            EnhancedStatCard(
                value: "8/25",
                title: "Sonraki",
                subtitle: "Usta",
                icon: "target",
                color: .blue
            )
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
} 