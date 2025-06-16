import SwiftUI

// MARK: - Achievement Icon Component
struct AchievementIconView: View {
    let achievement: Achievement
    let size: CGFloat
    let weight: Font.Weight
    
    var body: some View {
        if achievement.isCustomImage {
            // Custom Image from Assets - Circular clipped to medal size
            Image(achievement.displayIcon)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: medalFrameSize, height: medalFrameSize)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
        } else {
            // SF Symbol
            Image(systemName: achievement.displayIcon)
                .font(.system(size: size, weight: weight))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
        }
    }
    
    // Calculate medal frame size based on icon size
    private var medalFrameSize: CGFloat {
        switch size {
        case 20: return 32  // small -> fits in small medal
        case 30: return 50  // medium -> fits in 50x50 medal (main cards)
        case 40: return 120 // large -> fits in 120x120 medal (detail sheet)
        case 60: return 160 // extraLarge -> fits in very large medal
        default: return size * 1.67 // General ratio
        }
    }
}

// MARK: - Convenience Extensions
extension AchievementIconView {
    // Standard sizes for different contexts
    static func small(_ achievement: Achievement) -> AchievementIconView {
        AchievementIconView(achievement: achievement, size: 20, weight: .bold)
    }
    
    static func medium(_ achievement: Achievement) -> AchievementIconView {
        AchievementIconView(achievement: achievement, size: 30, weight: .bold)
    }
    
    static func large(_ achievement: Achievement) -> AchievementIconView {
        AchievementIconView(achievement: achievement, size: 40, weight: .medium)
    }
    
    static func extraLarge(_ achievement: Achievement) -> AchievementIconView {
        AchievementIconView(achievement: achievement, size: 60, weight: .medium)
    }
}

// MARK: - Preview
struct AchievementIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // SF Symbol example
            AchievementIconView.medium(Achievement(
                id: "test_sf",
                category: .firstSteps,
                type: .milestone,
                title: "Test SF",
                description: "Test",
                iconName: "trophy.fill",
                imageName: nil,
                target: 10,
                isHidden: false,
                rarity: .common
            ))
            
            // Custom image example  
            AchievementIconView.medium(Achievement(
                id: "test_custom",
                category: .firstSteps,
                type: .milestone,
                title: "Test Custom",
                description: "Test",
                iconName: "trophy.fill",
                imageName: "achievement_custom_icon",
                target: 10,
                isHidden: false,
                rarity: .common
            ))
        }
        .padding()
        .background(Color.black)
    }
} 