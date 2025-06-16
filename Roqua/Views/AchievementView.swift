import SwiftUI

struct AchievementView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedType: AchievementType = .milestone
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Stats
                    headerStatsView
                    
                    // Insights Section
                    if !achievementManager.insights.isEmpty {
                        insightsSection
                    }
                    
                    // Recent Unlocks
                    if !achievementManager.recentUnlocks.isEmpty {
                        recentUnlocksSection
                    }
                    
                    // Achievement Type Filter
                    achievementTypeFilter
                    
                    // Achievements Grid
                    achievementsGrid
                }
                .padding()
            }
            .navigationTitle("Başarımlar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            achievementManager.refreshProgress()
        }
    }
    
    // MARK: - Header Stats
    
    private var headerStatsView: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Açılan",
                value: "\(achievementManager.totalUnlockedCount)",
                subtitle: "/ \(achievementManager.achievements.count)",
                color: .green,
                icon: "trophy.fill"
            )
            
            StatCard(
                title: "İlerleme",
                value: String(format: "%.0f%%", progressPercentage),
                subtitle: "tamamlandı",
                color: .blue,
                icon: "chart.pie.fill"
            )
            
            StatCard(
                title: "Son Açılan",
                value: "\(achievementManager.recentUnlocks.count)",
                subtitle: "bu hafta",
                color: .orange,
                icon: "star.fill"
            )
        }
    }
    
    private var progressPercentage: Double {
        guard !achievementManager.achievements.isEmpty else { return 0 }
        return Double(achievementManager.totalUnlockedCount) / Double(achievementManager.achievements.count) * 100
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Keşif İçgörüleri")
                    .font(.headline)
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(achievementManager.insights.prefix(3)) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Recent Unlocks
    
    private var recentUnlocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Son Açılanlar")
                    .font(.headline)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievementManager.recentUnlocks.suffix(5)) { progress in
                        if let achievement = achievementManager.getAchievement(by: progress.achievementId) {
                            RecentUnlockCard(achievement: achievement, progress: progress)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Achievement Type Filter
    
    private var achievementTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AchievementType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                    }) {
                        HStack {
                            Image(systemName: iconForType(type))
                            Text(titleForType(type))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedType == type ? Color.blue : Color(.systemGray5))
                        .foregroundColor(selectedType == type ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Achievements Grid
    
    private var achievementsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(filteredAchievements) { achievement in
                AchievementCard(
                    achievement: achievement,
                    progress: achievementManager.getProgress(for: achievement.id)
                )
            }
        }
    }
    
    private var filteredAchievements: [Achievement] {
        achievementManager.getAchievements(by: selectedType)
    }
    
    // MARK: - Helper Functions
    
    private func titleForType(_ type: AchievementType) -> String {
        switch type {
        case .geographic: return "Coğrafi"
        case .exploration: return "Keşif"
        case .temporal: return "Zaman"
        case .milestone: return "Kilometre Taşı"
        }
    }
    
    private func iconForType(_ type: AchievementType) -> String {
        switch type {
        case .geographic: return "globe.europe.africa.fill"
        case .exploration: return "map.fill"
        case .temporal: return "clock.fill"
        case .milestone: return "flag.fill"
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct InsightCard: View {
    let insight: UserInsight
    
    var body: some View {
        HStack {
            Image(systemName: insight.iconName)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(insight.value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
}

struct RecentUnlockCard: View {
    let achievement: Achievement
    let progress: AchievementProgress
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(colorForRarity(achievement.rarity))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.iconName)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let unlockedAt = progress.unlockedAt {
                Text(timeAgoString(from: unlockedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80)
    }
    
    private func colorForRarity(_ rarity: Achievement.AchievementRarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let progress: AchievementProgress?
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon and Status
            ZStack {
                Circle()
                    .fill(isUnlocked ? colorForRarity(achievement.rarity) : Color(.systemGray4))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .opacity(isUnlocked ? 1.0 : 0.6)
                
                if isUnlocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                    .frame(width: 60, height: 60)
                }
            }
            
            // Title and Description
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Progress
            if let progress = progress {
                VStack(spacing: 4) {
                    ProgressView(value: Double(progress.currentProgress), total: Double(progress.targetProgress))
                        .progressViewStyle(LinearProgressViewStyle(tint: colorForRarity(achievement.rarity)))
                    
                    Text("\(progress.currentProgress) / \(progress.targetProgress)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Rarity Badge
            Text(rarityText(achievement.rarity))
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(colorForRarity(achievement.rarity).opacity(0.2))
                .foregroundColor(colorForRarity(achievement.rarity))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: isUnlocked ? 4 : 2)
        .scaleEffect(isUnlocked ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isUnlocked)
    }
    
    private var isUnlocked: Bool {
        progress?.isUnlocked ?? false
    }
    
    private func colorForRarity(_ rarity: Achievement.AchievementRarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    private func rarityText(_ rarity: Achievement.AchievementRarity) -> String {
        switch rarity {
        case .common: return "Yaygın"
        case .rare: return "Nadir"
        case .epic: return "Epik"
        case .legendary: return "Efsanevi"
        }
    }
}

// MARK: - Preview

struct AchievementView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementView()
    }
} 