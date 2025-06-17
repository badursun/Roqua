import SwiftUI

// MARK: - Achievement Header
struct AchievementHeader: View {
    @ObservedObject var achievementManager: AchievementManager
    let onBackTap: () -> Void
    
    private var totalAchievements: Int {
        achievementManager.achievements.count
    }
    
    private var unlockedCount: Int {
        achievementManager.totalUnlockedCount
    }
    
    var body: some View {
        // Header Section - sadece üst kısım
        HStack {
                // Back Button
                Button(action: onBackTap) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.2))
                        .clipShape(Circle())
                }
                
                VStack(spacing: 4) {
                    Text("Ödüller")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    // Award Count Badge
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                        
                        Text("Award \(unlockedCount)/\(totalAchievements)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color.progressGradientStart, Color.progressGradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Trophy Icon with gradient background - daha büyük
                ZStack {
                    // Outer glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.progressGradientEnd.opacity(0.3),
                                    Color.progressGradientStart.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 3)
                    
                    // Inner Trophy Background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.progressGradientEnd.opacity(0.8),
                                    Color.progressGradientStart.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    // Trophy Icon
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.progressGradientEnd.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                }
            }
    }
}

// MARK: - Filter Tab
struct FilterTab: View {
    let filter: AchievementFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: filter.icon)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(filter.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(isSelected ? .primaryText : .secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                
                // Bottom border - only for selected
                Rectangle()
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            colors: [Color.progressGradientStart, Color.progressGradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) : 
                        LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 3)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Tabs Component
struct AchievementFilterTabs: View {
    @Binding var selectedFilter: AchievementFilter
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AchievementFilter.allCases, id: \.rawValue) { filter in
                FilterTab(
                    filter: filter,
                    isSelected: selectedFilter == filter,
                    onTap: { selectedFilter = filter }
                )
            }
        }
    }
}

// MARK: - Preview
struct AchievementHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Light mode
            VStack {
                AchievementHeader(
                    achievementManager: AchievementManager.shared,
                    onBackTap: {}
                )
                .padding()
                
                Text("Light Mode")
                    .font(.caption)
            }
            .background(Color.appBackground)
            .preferredColorScheme(.light)
            
            // Dark mode
            VStack {
                AchievementHeader(
                    achievementManager: AchievementManager.shared,
                    onBackTap: {}
                )
                .padding()
                
                Text("Dark Mode")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .background(Color.appBackground)
            .preferredColorScheme(.dark)
        }
    }
} 