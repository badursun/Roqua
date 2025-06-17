import SwiftUI

// MARK: - Modern Achievement Card
struct ModernAchievementCard: View {
    let achievement: Achievement
    let progress: AchievementProgress?
    let onTap: () -> Void
    
    private var currentProgress: Int {
        progress?.currentProgress ?? 0
    }
    
    private var progressPercentage: Double {
        progress?.progressPercentage ?? 0
    }
    
    private var isUnlocked: Bool {
        progress?.isUnlocked ?? false
    }
    
    private var statusText: String {
        if isUnlocked {
            return "Completed"
        } else {
            return "Next"
        }
    }
    
    // Medal colors based on rarity
    private var medalColors: [Color] {
        switch achievement.rarity {
        case .common:
            return [Color(red: 0.8, green: 0.8, blue: 0.85), Color(red: 0.6, green: 0.6, blue: 0.65)]
        case .rare:
            return [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.8, green: 0.65, blue: 0.1)]
        case .epic:
            return [Color(red: 0.8, green: 0.4, blue: 1.0), Color(red: 0.5, green: 0.2, blue: 0.8)]
        case .legendary:
            return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.8, green: 0.3, blue: 0.0)]
        }
    }
    
    private var outerRingColors: [Color] {
        switch achievement.rarity {
        case .common:
            return [Color(red: 0.9, green: 0.9, blue: 0.95), Color(red: 0.7, green: 0.7, blue: 0.75)]
        case .rare:
            return [Color(red: 1.0, green: 0.9, blue: 0.4), Color(red: 0.9, green: 0.7, blue: 0.2)]
        case .epic:
            return [Color(red: 0.9, green: 0.5, blue: 1.0), Color(red: 0.6, green: 0.3, blue: 0.9)]
        case .legendary:
            return [Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 0.9, green: 0.4, blue: 0.1)]
        }
    }
    
    private var medalShadowColor: Color {
        switch achievement.rarity {
        case .common: 
            return Color(red: 0.8, green: 0.8, blue: 0.85).opacity(0.4)
        case .rare: 
            return Color(red: 1.0, green: 0.85, blue: 0.3).opacity(0.4)
        case .epic: 
            return Color(red: 0.8, green: 0.4, blue: 1.0).opacity(0.4)
        case .legendary: 
            return Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.5)
        }
    }
    
    // Eski koddan rarity text
    private var rarityText: String {
        switch achievement.rarity {
        case .common: return "Yaygın"
        case .rare: return "Nadir"
        case .epic: return "Epik"
        case .legendary: return "Efsanevi"
        }
    }
    
    private var rarityBadgeColor: Color {
        switch achievement.rarity {
        case .common: return Color(red: 0.8, green: 0.8, blue: 0.85)
        case .rare: return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .epic: return Color(red: 0.8, green: 0.4, blue: 1.0)
        case .legendary: return Color(red: 1.0, green: 0.6, blue: 0.2)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main Card Content
                VStack(spacing: 6) {
                    // Badge at top
                    HStack {
                        Text(rarityText)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                rarityBadgeColor
                                    .clipShape(Capsule())
                            )
                        
                        Spacer()
                        
                        // Status badge - sadece completed renkli
                        Text(statusText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isUnlocked ? .white : .secondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(isUnlocked ? .green : Color.gray.opacity(0.3))
                            )
                    }
                    
                    // Icon with Medal Frame
                    ZStack {
                        // Outer Ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: outerRingColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 78, height: 78) // %35 daha büyük (58 -> 78)
                        
                        // Inner Medal
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: medalColors,
                                    center: UnitPoint(x: 0.3, y: 0.3),
                                    startRadius: 5,
                                    endRadius: 32
                                )
                            )
                            .frame(width: 67, height: 67) // %35 daha büyük (50 -> 67)
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
                                    .frame(width: 67, height: 67)
                            )
                        
                        // Achievement Icon
                        AchievementIconView.medium(achievement)
                            .scaleEffect(1.35) // %35 daha büyük
                    }
                    .shadow(color: medalShadowColor, radius: 8, x: 0, y: 4)
                    .grayscale(isUnlocked ? 0.0 : 1.0) // Kazanılmamış ödüller grayscale
                    
                    // Title (2-line fixed height)
                    Text(achievement.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                        .frame(height: 36) // Fixed height for 2 lines
                    
                    Spacer(minLength: 0)
                }
                .padding(20)
                
                // Progress Bar at bottom
                VStack(spacing: 4) {
                    // Progress text - tek satır
                    HStack {
                        Text("\(currentProgress)/\(achievement.target)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondaryText)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(Int(progressPercentage))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primaryText)
                            .lineLimit(1)
                    }
                    
                    // Progress bar - daha tombul
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            // Progress fill
                            Rectangle()
                                .fill(Color.progressGradient)
                                .frame(width: geometry.size.width * (progressPercentage / 100), height: 8)
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .overlay(
                    // Kazanılan ödül altın border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isUnlocked ? 
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.8, green: 0.65, blue: 0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isUnlocked ? 2 : 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .aspectRatio(0.85, contentMode: .fit) // Uniform card proportions
    }
}

// MARK: - Preview
struct ModernAchievementCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleAchievement = Achievement(
            id: "sample",
            category: .firstSteps,
            type: .milestone,
            title: "First Explorer",
            description: "Visit your first location",
            iconName: "trophy.fill",
            imageName: nil,
            target: 10,
            isHidden: false,
            rarity: .rare
        )
        
        let sampleProgress = AchievementProgress(
            id: "sample-progress",
            achievementId: "sample",
            currentProgress: 7,
            targetProgress: 10,
            isUnlocked: false,
            unlockedAt: nil,
            lastUpdated: Date()
        )
        
        VStack(spacing: 20) {
            // Light mode
            HStack(spacing: 15) {
                ModernAchievementCard(
                    achievement: sampleAchievement,
                    progress: sampleProgress,
                    onTap: {}
                )
                .frame(width: 160, height: 200)
                
                ModernAchievementCard(
                    achievement: Achievement(
                        id: "unlocked",
                        category: .firstSteps,
                        type: .milestone,
                        title: "Completed Achievement With Long Title",
                        description: "Description",
                        iconName: "star.fill",
                        imageName: nil,
                        target: 5,
                        isHidden: false,
                        rarity: .legendary
                    ),
                    progress: AchievementProgress(
                        id: "unlocked-progress",
                        achievementId: "unlocked",
                        currentProgress: 5,
                        targetProgress: 5,
                        isUnlocked: true,
                        unlockedAt: Date(),
                        lastUpdated: Date()
                    ),
                    onTap: {}
                )
                .frame(width: 160, height: 200)
            }
            
            Text("Light Mode")
                .font(.caption)
        }
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.light)
        
        VStack(spacing: 20) {
            // Dark mode
            HStack(spacing: 15) {
                ModernAchievementCard(
                    achievement: sampleAchievement,
                    progress: sampleProgress,
                    onTap: {}
                )
                .frame(width: 160, height: 200)
                
                ModernAchievementCard(
                    achievement: Achievement(
                        id: "unlocked-dark",
                        category: .firstSteps,
                        type: .milestone,
                        title: "Completed Achievement",
                        description: "Description",
                        iconName: "star.fill",
                        imageName: nil,
                        target: 5,
                        isHidden: false,
                        rarity: .epic
                    ),
                    progress: AchievementProgress(
                        id: "unlocked-dark-progress",
                        achievementId: "unlocked-dark",
                        currentProgress: 5,
                        targetProgress: 5,
                        isUnlocked: true,
                        unlockedAt: Date(),
                        lastUpdated: Date()
                    ),
                    onTap: {}
                )
                .frame(width: 160, height: 200)
            }
            
            Text("Dark Mode")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
    }
} 