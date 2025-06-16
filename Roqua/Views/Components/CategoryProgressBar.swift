import SwiftUI

// MARK: - Category Progress Bar Component
struct CategoryProgressBar: View {
    let completionRatio: Double // 0.0 to 1.0
    let completedCount: Int
    let totalCount: Int
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        VStack(spacing: 6) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 12)
                    
                    // Progress Fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: progressColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * animatedProgress,
                            height: 12
                        )
                        .overlay(
                            // Shimmer Effect
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.2),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * animatedProgress,
                                    height: 12
                                )
                        )
                        .animation(.easeInOut(duration: 1.2), value: animatedProgress)
                }
            }
            .frame(height: 12)
            
            // Completion Text
            HStack {
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("\(Int(completionRatio * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(completionRatio >= 1.0 ? .green : .white.opacity(0.7))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                animatedProgress = completionRatio
            }
        }
        .onChange(of: completionRatio) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
    
    private var progressColors: [Color] {
        if completionRatio >= 1.0 {
            // Completed - Green to Gold gradient
            return [.green, Color(red: 0.2, green: 0.8, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.0)]
        } else if completionRatio >= 0.8 {
            // Near completion - Orange to Yellow
            return [.orange, Color(red: 1.0, green: 0.8, blue: 0.0)]
        } else if completionRatio >= 0.5 {
            // Good progress - Blue to Purple
            return [.blue, .purple]
        } else {
            // Starting - Gray to Blue
            return [Color.gray.opacity(0.8), .blue]
        }
    }
}

// MARK: - Completion Badge Component
struct CompletionBadge: View {
    let completionRatio: Double
    let isFullyMastered: Bool // All achievements unlocked
    
    @State private var isAnimating = false
    
    var body: some View {
        if completionRatio >= 1.0 {
            ZStack {
                // Badge Background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: badgeColors,
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 15
                        )
                    )
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                // Badge Icon
                Image(systemName: badgeIcon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .shadow(color: badgeColors.first?.opacity(0.5) ?? .clear, radius: 6, x: 0, y: 3)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating.toggle()
                }
            }
        }
    }
    
    private var badgeColors: [Color] {
        if isFullyMastered {
            // Gold Crown for fully mastered
            return [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 0.8, green: 0.6, blue: 0.0)]
        } else {
            // Green checkmark for completed
            return [.green, Color(red: 0.2, green: 0.8, blue: 0.2)]
        }
    }
    
    private var badgeIcon: String {
        isFullyMastered ? "crown.fill" : "checkmark"
    }
}

// MARK: - Difficulty Rating Component
struct DifficultyRating: View {
    let difficulty: Int // 1-5 stars
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= difficulty ? "star.fill" : "star")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(star <= difficulty ? Color(red: 1.0, green: 0.8, blue: 0.0) : .white.opacity(0.3))
            }
        }
    }
}



// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        CategoryProgressBar(completionRatio: 0.75, completedCount: 6, totalCount: 8)
        
        HStack {
            CompletionBadge(completionRatio: 1.0, isFullyMastered: false)
            CompletionBadge(completionRatio: 1.0, isFullyMastered: true)
            DifficultyRating(difficulty: 3)
        }
    }
    .padding()
    .background(.black)
} 