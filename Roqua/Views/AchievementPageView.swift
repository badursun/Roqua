import SwiftUI

// MARK: - Main Achievement Page
struct AchievementPageView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Beautiful gradient background like onboarding
            LinearGradient(
                colors: [.black, .blue.opacity(0.8), .purple.opacity(0.6), .orange.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Compact Header Summary
                CompactAchievementSummary()
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                
                // Enhanced Tab View with better visibility
                VStack(spacing: 0) {
                    // Custom Tab Bar
                    HStack(spacing: 12) {
                        TabButton(
                            title: "Ödüllerim",
                            icon: "trophy.fill",
                            isSelected: selectedTab == 0,
                            action: { selectedTab = 0 }
                        )
                        
                        TabButton(
                            title: "Tüm Ödüller",
                            icon: "list.bullet",
                            isSelected: selectedTab == 1,
                            action: { selectedTab = 1 }
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        MyAchievementsView()
                            .tag(0)
                        
                        AllAchievementsView()
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
        }
        .navigationTitle("Başarımlar")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear {
            achievementManager.refreshProgress()
        }
    }
}

// MARK: - Custom Tab Button
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                    
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Spacer()
            }
            .frame(height: 60)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .purple.opacity(0.8), .blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Premium Achievement Summary
struct CompactAchievementSummary: View {
    @StateObject private var achievementManager = AchievementManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Premium Display
            VStack(spacing: 12) {
                // Large Trophy Icon with Progress Ring
                ZStack {
                    // Outer glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(0.3),
                                    Color.orange.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                        .blur(radius: 3)
                    
                    // Animated Progress Ring
                    CircularProgressRing(
                        progress: progressPercentage / 100.0,
                        lineWidth: 4,
                        diameter: 60
                    )
                    
                    // Inner Trophy Background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.8),
                                    Color.orange.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    // Trophy Icon
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .yellow.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                }
                
                // Main Stats
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(achievementManager.totalUnlockedCount)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .yellow.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                        
                        Text("/")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("\(achievementManager.achievements.count)")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    
                    Text("Kazanılan Ödül")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
            }
            
            // Enhanced Stats Row
            HStack(spacing: 8) {
                // Streak Card (highlighted if active)
                EnhancedStatCard(
                    value: "\(achievementManager.currentStreak)",
                    title: "Günlük Seri",
                    subtitle: achievementManager.currentStreak > 0 ? "🔥 Aktif!" : nil,
                    icon: "flame.fill",
                    color: .orange,
                    isHighlighted: achievementManager.currentStreak > 0
                )
                
                // Monthly Progress
                EnhancedStatCard(
                    value: "\(achievementManager.monthlyUnlockedCount)",
                    title: "Bu Ay",
                    icon: "calendar.badge.plus",
                    color: .green
                )
                
                // Point System
                EnhancedStatCard(
                    value: "\(achievementManager.totalPoints)",
                    title: "Toplam Puan",
                    subtitle: pointsLevelName,
                    icon: "star.circle.fill",
                    color: .purple
                )
                
                // Next Milestone
                EnhancedStatCard(
                    value: "\(nextMilestone.current)/\(nextMilestone.target)",
                    title: "Sonraki",
                    subtitle: nextMilestone.name,
                    icon: "target",
                    color: .blue
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private var progressPercentage: Double {
        guard !achievementManager.achievements.isEmpty else { return 0 }
        return Double(achievementManager.totalUnlockedCount) / Double(achievementManager.achievements.count) * 100
    }
    
    private var recentUnlocksCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return achievementManager.recentUnlocks.filter { 
            $0.unlockedAt ?? Date.distantPast > weekAgo 
        }.count
    }
    
    private var highestRarityCount: String {
        let unlockedAchievements = achievementManager.achievements.filter { achievement in
            achievementManager.getProgress(for: achievement.id)?.isUnlocked ?? false
        }
        
        let legendaryCont = unlockedAchievements.filter { $0.rarity == .legendary }.count
        let epicCount = unlockedAchievements.filter { $0.rarity == .epic }.count
        let rareCount = unlockedAchievements.filter { $0.rarity == .rare }.count
        
        if legendaryCont > 0 { return "\(legendaryCont)" }
        if epicCount > 0 { return "\(epicCount)" }
        if rareCount > 0 { return "\(rareCount)" }
        return "0"
    }
    
    private var highestRarityName: String {
        let unlockedAchievements = achievementManager.achievements.filter { achievement in
            achievementManager.getProgress(for: achievement.id)?.isUnlocked ?? false
        }
        
        let legendaryCont = unlockedAchievements.filter { $0.rarity == .legendary }.count
        let epicCount = unlockedAchievements.filter { $0.rarity == .epic }.count
        let rareCount = unlockedAchievements.filter { $0.rarity == .rare }.count
        
        if legendaryCont > 0 { return "Efsanevi" }
        if epicCount > 0 { return "Epik" }
        if rareCount > 0 { return "Nadir" }
        return "Yaygın"
    }
    
    private var pointsLevelName: String {
        let points = achievementManager.totalPoints
        switch points {
        case 0..<10: return "Acemi"
        case 10..<25: return "Gelişen"
        case 25..<50: return "Usta"
        case 50..<100: return "Uzman"
        case 100..<200: return "Efsane"
        default: return "Ölümsüz"
        }
    }
    
    private var nextMilestone: (target: Int, current: Int, name: String) {
        return achievementManager.nextMilestone
    }
}

// MARK: - Secondary Stat Card (Compact Premium)
struct SecondaryStatCard: View {
    let value: String
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            // Premium Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.4),
                                color.opacity(0.2)
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 12
                        )
                    )
                    .frame(width: 24, height: 24)
                
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, color.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            // Value
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            // Title
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 65) // Fixed compact height
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Individual Stat Card (Uniform Size)
struct IndividualStatCard: View {
    let value: String
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            // Premium metallic icon on the side
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.1)
                            ],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 15
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Value with premium styling
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // Title with subtle styling
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .frame(height: 60) // Fixed height for all summary cards
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - My Achievements Tab
struct MyAchievementsView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedAchievement: Achievement?
    
    var body: some View {
        ScrollView {
            if unlockedAchievements.isEmpty {
                // Empty State
                VStack(spacing: 20) {
                    Image(systemName: "trophy")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Henüz Ödül Yok")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Keşfetmeye başlayarak ilk ödülünü kazan!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 80)
            } else {
                // Medal Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 4),
                    GridItem(.flexible(), spacing: 4)
                ], spacing: 8) {
                    ForEach(unlockedAchievements) { achievement in
                        AchievementMedalCard(
                            achievement: achievement,
                            progress: achievementManager.getProgress(for: achievement.id)
                        )
                        .onTapGesture {
                            selectedAchievement = achievement
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(
                achievement: achievement,
                progress: achievementManager.getProgress(for: achievement.id)
            )
        }
    }
    
    private var unlockedAchievements: [Achievement] {
        achievementManager.getUnlockedAchievements()
            .sorted { achievement1, achievement2 in
                let progress1 = achievementManager.getProgress(for: achievement1.id)
                let progress2 = achievementManager.getProgress(for: achievement2.id)
                
                // Most recently unlocked first
                let date1 = progress1?.unlockedAt ?? Date.distantPast
                let date2 = progress2?.unlockedAt ?? Date.distantPast
                return date1 > date2
            }
    }
}

// MARK: - All Achievements Tab
struct AllAchievementsView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedAchievement: Achievement?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Regular Achievements by Category
                ForEach(Array(groupedAchievements.keys).sorted { $0.rawValue < $1.rawValue }, id: \.self) { category in
                    CategoryListSection(
                        category: category,
                        achievements: groupedAchievements[category] ?? [],
                        onAchievementTap: { achievement in
                            selectedAchievement = achievement
                        }
                    )
                }
                
                // Hidden Achievements (if any unlocked)
                if !unlockedHiddenAchievements.isEmpty {
                    HiddenAchievementsSection(
                        achievements: unlockedHiddenAchievements,
                        onAchievementTap: { achievement in
                            selectedAchievement = achievement
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(
                achievement: achievement,
                progress: achievementManager.getProgress(for: achievement.id)
            )
        }
    }
    
    private var groupedAchievements: [AchievementCategory: [Achievement]] {
        let regularAchievements = achievementManager.achievements.filter { !$0.isHidden }
        return Dictionary(grouping: regularAchievements) { $0.category }
    }
    
    private var unlockedHiddenAchievements: [Achievement] {
        achievementManager.achievements
            .filter { $0.isHidden }
            .filter { achievement in
                achievementManager.getProgress(for: achievement.id)?.isUnlocked == true
            }
    }
}

// MARK: - Achievement Medal Card (Apple Fitness Style)
struct AchievementMedalCard: View {
    let achievement: Achievement
    let progress: AchievementProgress?
    
    var body: some View {
        VStack(spacing: 6) {
            // Medal Design - Same as UniformAchievementCard
            ZStack {
                // Outer Ring - Always colored
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: enhancedOuterRingColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 58, height: 58)
                
                // Inner Medal - Always colored
                Circle()
                    .fill(
                        RadialGradient(
                            colors: enhancedMedalColors,
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 4,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: UnitPoint(x: 0.2, y: 0.2),
                                    endPoint: UnitPoint(x: 0.8, y: 0.8)
                                )
                            )
                            .frame(width: 50, height: 50)
                    )
                
                // Achievement Icon
                Image(systemName: achievement.iconName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            }
            .shadow(color: enhancedMedalShadowColor, radius: 8, x: 0, y: 4)
            
            // Title with 3 lines + Rarity
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .frame(height: 48) // Fixed height for 3 lines with larger font
                
                // Rarity Label
                Text(rarityName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(rarityColor)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .frame(height: 14)
                
                // Unlock Date
                if let progress = progress, let unlockedAt = progress.unlockedAt {
                    Text(formatUnlockDate(unlockedAt))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        .frame(height: 14)
                } else {
                    Spacer()
                        .frame(height: 14)
                }
            }
        }
        .frame(width: 140, height: 180) // Same size as UniformAchievementCard
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.green.opacity(0.6), Color.green.opacity(0.3)], // Always green for unlocked
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
    }
    
    private var rarityName: String {
        switch achievement.rarity {
        case .common: return "Yaygın"
        case .rare: return "Nadir"
        case .epic: return "Epik"
        case .legendary: return "Efsanevi"
        }
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: return Color(red: 0.8, green: 0.8, blue: 0.85)
        case .rare: return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .epic: return Color(red: 0.8, green: 0.4, blue: 1.0)
        case .legendary: return Color(red: 1.0, green: 0.6, blue: 0.2)
        }
    }
    
    private var enhancedMedalColors: [Color] {
        switch achievement.rarity {
        case .common:
            return [Color(red: 0.8, green: 0.8, blue: 0.85), Color(red: 0.6, green: 0.6, blue: 0.65)] // Silver
        case .rare:
            return [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.8, green: 0.65, blue: 0.1)] // Gold
        case .epic:
            return [Color(red: 0.8, green: 0.4, blue: 1.0), Color(red: 0.5, green: 0.2, blue: 0.8)] // Purple
        case .legendary:
            return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.8, green: 0.3, blue: 0.0)] // Orange
        }
    }
    
    private var enhancedOuterRingColors: [Color] {
        switch achievement.rarity {
        case .common:
            return [Color(red: 0.9, green: 0.9, blue: 0.95), Color(red: 0.7, green: 0.7, blue: 0.75)] // Silver ring
        case .rare:
            return [Color(red: 1.0, green: 0.9, blue: 0.4), Color(red: 0.9, green: 0.7, blue: 0.2)] // Gold ring
        case .epic:
            return [Color(red: 0.9, green: 0.5, blue: 1.0), Color(red: 0.6, green: 0.3, blue: 0.9)] // Purple ring
        case .legendary:
            return [Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 0.9, green: 0.4, blue: 0.1)] // Orange ring
        }
    }
    
    private var enhancedMedalShadowColor: Color {
        switch achievement.rarity {
        case .common: return Color(red: 0.8, green: 0.8, blue: 0.85).opacity(0.4) // Silver shadow
        case .rare: return Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.4) // Gold shadow
        case .epic: return Color(red: 0.8, green: 0.4, blue: 1.0).opacity(0.4) // Purple shadow
        case .legendary: return Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.5) // Orange shadow
        }
    }
    
    private func formatUnlockDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Category List Section (No Card Background)
struct CategoryListSection: View {
    let category: AchievementCategory
    let achievements: [Achievement]
    let onAchievementTap: (Achievement) -> Void
    
    @StateObject private var achievementManager = AchievementManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Clean Category Header - No Badge
            HStack(alignment: .center, spacing: 8) {
                Text(titleForCategory(category))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Text("(\(unlockedCount)/\(achievements.count))")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Uniform Grid with Fixed Size Cards (2 Column)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ], spacing: 4) {
                ForEach(sortedAchievements) { achievement in
                    UniformAchievementCard(
                        achievement: achievement,
                        progress: achievementManager.getProgress(for: achievement.id)
                    )
                    .onTapGesture {
                        onAchievementTap(achievement)
                    }
                }
            }
        }
    }
    
    private var sortedAchievements: [Achievement] {
        achievements.sorted { achievement1, achievement2 in
            // First sort by unlocked status (unlocked first)
            let isUnlocked1 = achievementManager.getProgress(for: achievement1.id)?.isUnlocked ?? false
            let isUnlocked2 = achievementManager.getProgress(for: achievement2.id)?.isUnlocked ?? false
            
            if isUnlocked1 != isUnlocked2 {
                return isUnlocked1
            }
            
            // Then sort by target (easier first)
            return achievement1.target < achievement2.target
        }
    }
    
    private var unlockedCount: Int {
        achievements.filter { achievement in
            achievementManager.getProgress(for: achievement.id)?.isUnlocked ?? false
        }.count
    }
    
    private func titleForCategory(_ category: AchievementCategory) -> String {
        switch category {
        case .firstSteps: return "İlk Adımlar"
        case .explorer: return "Kaşif"
        case .adventurer: return "Maceracı"
        case .worldTraveler: return "Dünya Gezgini"
        case .cityMaster: return "Şehir Ustası"
        case .districtExplorer: return "İlçe Kaşifi"
        case .countryCollector: return "Ülke Koleksiyoneri"
        case .areaExplorer: return "Alan Kaşifi"
        case .distanceWalker: return "Mesafe Yürüyüşçüsü"
        case .gridMaster: return "Grid Ustası"
        case .percentageMilestone: return "Yüzde Milestone"
        case .dailyExplorer: return "Günlük Kaşif"
        case .weekendWarrior: return "Hafta Sonu Savaşçısı"
        case .monthlyChallenger: return "Aylık Meydan Okuyucu"
        }
    }
    
    private func iconForCategory(_ category: AchievementCategory) -> String {
        switch category {
        case .firstSteps: return "figure.walk"
        case .explorer: return "map"
        case .adventurer: return "mountain.2"
        case .worldTraveler: return "globe"
        case .cityMaster: return "building.2"
        case .districtExplorer: return "map.circle"
        case .countryCollector: return "globe.europe.africa"
        case .areaExplorer: return "square.grid.3x3"
        case .distanceWalker: return "figure.walk.diamond"
        case .gridMaster: return "grid"
        case .percentageMilestone: return "percent"
        case .dailyExplorer: return "calendar"
        case .weekendWarrior: return "sun.max"
        case .monthlyChallenger: return "calendar.badge.clock"
        }
    }
}

// MARK: - Uniform Achievement Card (Fixed Size)
struct UniformAchievementCard: View {
    let achievement: Achievement
    let progress: AchievementProgress?
    
    var body: some View {
        VStack(spacing: 6) {
            // Fixed Size Medal Design - Always Show Colors
            ZStack {
                // Outer Ring - Always colored
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: enhancedOuterRingColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 58, height: 58)
                    .opacity(isUnlocked ? 1.0 : 0.7) // Slightly faded if locked
                
                // Inner Medal - Always colored
                Circle()
                    .fill(
                        RadialGradient(
                            colors: enhancedMedalColors,
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 4,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .opacity(isUnlocked ? 1.0 : 0.6) // Slightly faded if locked
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: UnitPoint(x: 0.2, y: 0.2),
                                    endPoint: UnitPoint(x: 0.8, y: 0.8)
                                )
                            )
                            .frame(width: 50, height: 50)
                    )
                
                // Achievement Icon
                Image(systemName: achievement.iconName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(isUnlocked ? 1.0 : 0.8)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            }
            .shadow(color: enhancedMedalShadowColor, radius: 8, x: 0, y: 4)
            
            // Title with 3 lines + Rarity
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .frame(height: 48) // Fixed height for 3 lines with larger font
                
                // Rarity Label
                Text(rarityName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(rarityColor)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .frame(height: 14)
            }
            
            // Progress Info
            if let progress = progress, !isUnlocked {
                VStack(spacing: 2) {
                    ProgressView(value: Double(progress.currentProgress), total: Double(progress.targetProgress))
                        .progressViewStyle(LinearProgressViewStyle(tint: enhancedMedalColors.first ?? .gray))
                        .scaleEffect(x: 1, y: 0.8)
                        .frame(height: 4)
                    
                    Text("\(progress.currentProgress)/\(progress.targetProgress)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                .frame(height: 20)
            } else {
                Spacer()
                    .frame(height: 20) // Maintain consistent height
            }
        }
        .frame(width: 140, height: 180) // Even larger fixed card size for bigger icons + text
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: isUnlocked ? 
                                    [Color.green.opacity(0.6), Color.green.opacity(0.3)] : // Green border for unlocked
                                    [enhancedMedalColors.first?.opacity(0.4) ?? .clear, .clear], // Medal color for locked
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isUnlocked ? 2 : 1
                        )
                )
        )
    }
    
    private var isUnlocked: Bool {
        progress?.isUnlocked ?? false
    }
    
    private var rarityName: String {
        switch achievement.rarity {
        case .common: return "Yaygın"
        case .rare: return "Nadir"
        case .epic: return "Epik"
        case .legendary: return "Efsanevi"
        }
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: return Color(red: 0.8, green: 0.8, blue: 0.85)
        case .rare: return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .epic: return Color(red: 0.8, green: 0.4, blue: 1.0)
        case .legendary: return Color(red: 1.0, green: 0.6, blue: 0.2)
        }
    }
    
    private var enhancedMedalColors: [Color] {
        switch achievement.rarity {
        case .common:
            return [Color(red: 0.8, green: 0.8, blue: 0.85), Color(red: 0.6, green: 0.6, blue: 0.65)] // Silver
        case .rare:
            return [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.8, green: 0.65, blue: 0.1)] // Gold
        case .epic:
            return [Color(red: 0.8, green: 0.4, blue: 1.0), Color(red: 0.6, green: 0.2, blue: 0.8)] // Purple
        case .legendary:
            return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.8, green: 0.4, blue: 0.0)] // Orange
        }
    }
    
    private var enhancedOuterRingColors: [Color] {
        switch achievement.rarity {
        case .common:
            return [Color(red: 0.9, green: 0.9, blue: 0.95), Color(red: 0.7, green: 0.7, blue: 0.75)] // Silver ring
        case .rare:
            return [Color(red: 1.0, green: 0.9, blue: 0.4), Color(red: 0.9, green: 0.7, blue: 0.2)] // Gold ring
        case .epic:
            return [Color(red: 0.9, green: 0.5, blue: 1.0), Color(red: 0.7, green: 0.3, blue: 0.9)] // Purple ring
        case .legendary:
            return [Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 0.9, green: 0.5, blue: 0.1)] // Orange ring
        }
    }
    
    private var enhancedMedalShadowColor: Color {
        switch achievement.rarity {
        case .common: return Color(red: 0.8, green: 0.8, blue: 0.85).opacity(0.4) // Silver shadow
        case .rare: return Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.4) // Gold shadow
        case .epic: return Color(red: 0.8, green: 0.4, blue: 1.0).opacity(0.4) // Purple shadow
        case .legendary: return Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.5) // Orange shadow
        }
    }
}

// MARK: - Hidden Achievements Section
struct HiddenAchievementsSection: View {
    let achievements: [Achievement]
    let onAchievementTap: (Achievement) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "eye.slash")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text("Gizli Ödüller")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(achievements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            // Hidden Achievements
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(achievements) { achievement in
                    UniformAchievementCard(
                        achievement: achievement,
                        progress: AchievementManager.shared.getProgress(for: achievement.id)
                    )
                    .onTapGesture {
                        onAchievementTap(achievement)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Achievement Detail Sheet
struct AchievementDetailSheet: View {
    let achievement: Achievement
    let progress: AchievementProgress?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Large Medal
                    VStack(spacing: 16) {
                        ZStack {
                            // Outer Ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: outerRingColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 6
                                )
                                .frame(width: 140, height: 140)
                            
                            // Inner Medal
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: medalColors,
                                        center: .topLeading,
                                        startRadius: 20,
                                        endRadius: 70
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.3), Color.clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                )
                            
                            // Achievement Icon
                            Image(systemName: achievement.iconName)
                                .font(.system(size: 40))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .shadow(color: medalShadowColor, radius: 12, x: 0, y: 6)
                        
                        // Rarity Badge
                        Text(rarityText(achievement.rarity))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(colorForRarity(achievement.rarity).opacity(0.2))
                            .foregroundColor(colorForRarity(achievement.rarity))
                            .cornerRadius(16)
                    }
                    
                    // Achievement Info
                    VStack(spacing: 12) {
                        Text(achievement.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(achievement.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Progress Section
                    if let progress = progress {
                        VStack(spacing: 16) {
                            Divider()
                            
                            if progress.isUnlocked {
                                // Unlocked Info
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Ödül Kazanıldı")
                                            .fontWeight(.medium)
                                    }
                                    .font(.headline)
                                    
                                    if let unlockedAt = progress.unlockedAt {
                                        Text("Kazanıldığı Tarih: \(formatDate(unlockedAt))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                // Progress Info
                                VStack(spacing: 12) {
                                    Text("İlerleme")
                                        .font(.headline)
                                    
                                    ProgressView(value: Double(progress.currentProgress), total: Double(progress.targetProgress))
                                        .progressViewStyle(LinearProgressViewStyle(tint: colorForRarity(achievement.rarity)))
                                        .scaleEffect(x: 1, y: 2)
                                    
                                    HStack {
                                        Text("\(progress.currentProgress)")
                                            .fontWeight(.bold)
                                        Text("/ \(progress.targetProgress)")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.title3)
                                    
                                    let remaining = progress.targetProgress - progress.currentProgress
                                    if remaining > 0 {
                                        Text("\(remaining) daha gerek")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var medalColors: [Color] {
        switch achievement.rarity {
        case .common:
            return [Color(red: 0.8, green: 0.8, blue: 0.85), Color(red: 0.6, green: 0.6, blue: 0.65)] // Silver
        case .rare:
            return [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.8, green: 0.65, blue: 0.1)] // Gold
        case .epic:
            return [Color(red: 0.8, green: 0.4, blue: 1.0), Color(red: 0.6, green: 0.2, blue: 0.8)] // Purple
        case .legendary:
            return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.8, green: 0.4, blue: 0.0)] // Orange
        }
    }
    
    private var outerRingColors: [Color] {
        switch achievement.rarity {
        case .common:
            return [Color(red: 0.9, green: 0.9, blue: 0.95), Color(red: 0.7, green: 0.7, blue: 0.75)] // Silver ring
        case .rare:
            return [Color(red: 1.0, green: 0.9, blue: 0.4), Color(red: 0.9, green: 0.7, blue: 0.2)] // Gold ring
        case .epic:
            return [Color(red: 0.9, green: 0.5, blue: 1.0), Color(red: 0.7, green: 0.3, blue: 0.9)] // Purple ring
        case .legendary:
            return [Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 0.9, green: 0.5, blue: 0.1)] // Orange ring
        }
    }
    
    private var medalShadowColor: Color {
        switch achievement.rarity {
        case .common: return Color(red: 0.8, green: 0.8, blue: 0.85).opacity(0.4) // Silver shadow
        case .rare: return Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.4) // Gold shadow
        case .epic: return Color(red: 0.8, green: 0.4, blue: 1.0).opacity(0.4) // Purple shadow
        case .legendary: return Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.5) // Orange shadow
        }
    }
    
    private func colorForRarity(_ rarity: Achievement.AchievementRarity) -> Color {
        switch rarity {
        case .common: return Color(red: 0.8, green: 0.8, blue: 0.85) // Silver
        case .rare: return Color(red: 1.0, green: 0.85, blue: 0.3) // Gold
        case .epic: return Color(red: 0.8, green: 0.4, blue: 1.0) // Purple
        case .legendary: return Color(red: 1.0, green: 0.6, blue: 0.2) // Orange
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct AchievementPageView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementPageView()
    }
} 