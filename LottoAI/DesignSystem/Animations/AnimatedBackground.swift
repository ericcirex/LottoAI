import SwiftUI

/// 星空粒子背景
struct StarfieldBackground: View {
    @State private var stars: [Star] = []
    @State private var isAnimating = false

    let starCount: Int

    init(starCount: Int = 50) {
        self.starCount = starCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 渐变背景
                AppColors.backgroundGradient

                // 星星
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(star.position)
                        .opacity(star.opacity * (isAnimating ? 1 : 0.3))
                        .blur(radius: star.size > 2 ? 0.5 : 0)
                }
            }
            .onAppear {
                generateStars(in: geometry.size)
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .ignoresSafeArea()
    }

    private func generateStars(in size: CGSize) {
        stars = (0..<starCount).map { _ in
            Star(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.3...1.0)
            )
        }
    }
}

struct Star: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
}

/// 流动渐变背景
struct FlowingGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [
                AppColors.deepBlack,
                AppColors.spaceBlue,
                Color(hex: "1a0a2e"),
                AppColors.starBlue
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

/// 光晕效果
struct GlowOrb: View {
    let color: Color
    var size: CGFloat = 200
    var blur: CGFloat = 80

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.5), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: blur)
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .opacity(isAnimating ? 0.6 : 0.3)
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

/// 脉冲圆环
struct PulseRing: View {
    let color: Color
    var maxScale: CGFloat = 2.0
    var duration: Double = 2.0

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(isAnimating ? maxScale : 1)
            .opacity(isAnimating ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: duration).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

/// 微光效果 (用于加载状态)
struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.6)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

#Preview("Starfield") {
    StarfieldBackground()
}

#Preview("Flowing Gradient") {
    FlowingGradientBackground()
}

#Preview("Glow Orb") {
    ZStack {
        AppColors.backgroundGradient
            .ignoresSafeArea()

        GlowOrb(color: AppColors.gold)
    }
}
