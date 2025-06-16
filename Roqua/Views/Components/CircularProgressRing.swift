import SwiftUI

// MARK: - Circular Progress Ring Component
struct CircularProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let diameter: CGFloat
    
    @State private var animatedProgress: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    
    private var isNearCompletion: Bool {
        progress > 0.8
    }
    
    var body: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(
                    Color.white.opacity(0.2),
                    lineWidth: lineWidth
                )
                .frame(width: diameter, height: diameter)
            
            // Progress Ring with Gradient
            Circle()
                .trim(from: 0.0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.yellow.opacity(0.8),
                            Color.orange.opacity(0.9),
                            Color.yellow
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: Color.yellow.opacity(0.3),
                    radius: isNearCompletion ? 6 : 3,
                    x: 0,
                    y: 0
                )
                .scaleEffect(isNearCompletion ? pulseScale : 1.0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: pulseScale
                )
        }
        .onAppear {
            // Smooth progress animation
            withAnimation(.easeInOut(duration: 1.5)) {
                animatedProgress = progress
            }
            
            // Start pulsing if near completion
            if isNearCompletion {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            }
        }
        .onChange(of: progress) { _, newProgress in
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = newProgress
            }
            
            // Update pulsing based on new progress
            if newProgress > 0.8 && !isNearCompletion {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            } else if newProgress <= 0.8 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    pulseScale = 1.0
                }
            }
        }
    }
}

// MARK: - Animated Counter Text
struct AnimatedCounterText: View {
    let targetValue: Double
    let suffix: String
    let font: Font
    let color: Color
    
    @State private var currentValue: Double = 0.0
    
    var body: some View {
        Text("\(Int(currentValue))\(suffix)")
            .font(font)
            .foregroundColor(color)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5)) {
                    currentValue = targetValue
                }
            }
            .onChange(of: targetValue) { _, newValue in
                withAnimation(.easeInOut(duration: 1.0)) {
                    currentValue = newValue
                }
            }
    }
}

// MARK: - Preview
struct CircularProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Low Progress
            ZStack {
                CircularProgressRing(
                    progress: 0.25,
                    lineWidth: 6,
                    diameter: 80
                )
                
                VStack {
                    AnimatedCounterText(
                        targetValue: 25,
                        suffix: "%",
                        font: .system(size: 16, weight: .bold),
                        color: .white
                    )
                }
            }
            
            // High Progress (with pulsing)
            ZStack {
                CircularProgressRing(
                    progress: 0.85,
                    lineWidth: 6,
                    diameter: 80
                )
                
                VStack {
                    AnimatedCounterText(
                        targetValue: 85,
                        suffix: "%",
                        font: .system(size: 16, weight: .bold),
                        color: .white
                    )
                }
            }
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
} 