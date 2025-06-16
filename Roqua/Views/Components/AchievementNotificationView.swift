import SwiftUI

struct AchievementNotificationView: View {
    let achievement: Achievement
    let progress: AchievementProgress
    @Binding var isVisible: Bool
    
    @State private var offset: CGFloat = -200
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // Achievement Icon
            ZStack {
                Circle()
                    .fill(colorForRarity(achievement.rarity))
                    .frame(width: 50, height: 50)
                
                AchievementIconView.small(achievement)
                
                // Sparkle effect
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .offset(x: 20, y: -20)
                    .opacity(opacity)
            }
            
            // Achievement Info
            VStack(alignment: .leading, spacing: 4) {
                Text("🏆 Başarım Açıldı!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Rarity Badge
            Text(rarityText(achievement.rarity))
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorForRarity(achievement.rarity).opacity(0.2))
                .foregroundColor(colorForRarity(achievement.rarity))
                .cornerRadius(8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [colorForRarity(achievement.rarity).opacity(0.6), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: colorForRarity(achievement.rarity).opacity(0.3), radius: 10, x: 0, y: 5)
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            showNotification()
        }
        .onTapGesture {
            hideNotification()
        }
    }
    
    private func showNotification() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            offset = 0
            scale = 1.0
            opacity = 1.0
        }
        
        // Sparkle animation
        withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
            opacity = 1.0
        }
        
        // Auto-hide after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            hideNotification()
        }
    }
    
    private func hideNotification() {
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = -200
            scale = 0.8
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isVisible = false
        }
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
        case .common: return "YAYGIN"
        case .rare: return "NADİR"
        case .epic: return "EPİK"
        case .legendary: return "EFSANE"
        }
    }
}

// MARK: - Achievement Notification Manager

@MainActor
class AchievementNotificationManager: ObservableObject {
    static let shared = AchievementNotificationManager()
    
    @Published var currentNotification: (achievement: Achievement, progress: AchievementProgress)?
    @Published var isShowingNotification = false
    
    private var notificationQueue: [(Achievement, AchievementProgress)] = []
    
    private init() {}
    
    func showAchievementUnlock(achievement: Achievement, progress: AchievementProgress) {
        // Add to queue
        notificationQueue.append((achievement, progress))
        
        // Show if not currently showing
        if !isShowingNotification {
            showNextNotification()
        }
    }
    
    private func showNextNotification() {
        guard !notificationQueue.isEmpty else { return }
        
        let (achievement, progress) = notificationQueue.removeFirst()
        currentNotification = (achievement, progress)
        isShowingNotification = true
        
        // Schedule next notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            if !self.notificationQueue.isEmpty {
                self.showNextNotification()
            }
        }
    }
    
    func hideCurrentNotification() {
        isShowingNotification = false
        currentNotification = nil
        
        // Show next if available
        if !notificationQueue.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showNextNotification()
            }
        }
    }
}

// MARK: - Preview

struct AchievementNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                AchievementNotificationView(
                    achievement: Achievement(
                        id: "first_steps",
                        category: .firstSteps,
                        type: .milestone,
                        title: "İlk Adımlar",
                        description: "İlk 10 bölgeyi keşfet",
                        iconName: "figure.walk",
                        imageName: nil,
                        target: 10,
                        isHidden: false,
                        rarity: .common
                    ),
                    progress: AchievementProgress(
                        id: "test",
                        achievementId: "first_steps",
                        currentProgress: 10,
                        targetProgress: 10,
                        isUnlocked: true,
                        unlockedAt: Date(),
                        lastUpdated: Date()
                    ),
                    isVisible: .constant(true)
                )
                .padding()
                
                Spacer()
            }
        }
    }
} 