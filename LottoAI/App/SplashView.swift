import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // 背景
                AppColors.backgroundGradient
                    .ignoresSafeArea()

                // 动态粒子背景
                ParticleBackground()

                VStack(spacing: 24) {
                    // Logo 动画区域
                    ZStack {
                        // 外环动画
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [AppColors.gold.opacity(0.5), AppColors.gold.opacity(0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 140 + CGFloat(i) * 30, height: 140 + CGFloat(i) * 30)
                                .scaleEffect(ringScale)
                                .opacity(ringOpacity)
                        }

                        // 发光背景
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AppColors.gold.opacity(0.3), AppColors.gold.opacity(0)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(logoScale)

                        // 主 Logo
                        ZStack {
                            Circle()
                                .fill(AppColors.goldShine)
                                .frame(width: 100, height: 100)
                                .shadow(color: AppColors.gold.opacity(0.5), radius: 20)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    }
                    .frame(height: 200)

                    // 文字
                    VStack(spacing: 8) {
                        Text("Lotto AI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, AppColors.gold],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("Your Lucky Number Companion")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .opacity(textOpacity)
                }
            }
            .onAppear {
                animateSplash()
            }
        }
    }

    private func animateSplash() {
        // Logo 淡入 + 缩放
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // 环形动画
        withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
            ringScale = 1.2
            ringOpacity = 0.5
        }

        // 文字淡入
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            textOpacity = 1.0
        }

        // 过渡到主界面
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isActive = true
            }
        }
    }
}

// MARK: - 粒子背景
struct ParticleBackground: View {
    @State private var particles: [Particle] = []

    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(AppColors.gold.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
            }
        }
        .onAppear {
            createParticles()
        }
    }

    private func createParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for _ in 0..<20 {
            let particle = Particle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                ),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.4)
            )
            particles.append(particle)
        }

        // 动画粒子
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in 0..<particles.count {
                particles[i].position.y -= 0.5
                if particles[i].position.y < -10 {
                    particles[i].position.y = screenHeight + 10
                    particles[i].position.x = CGFloat.random(in: 0...screenWidth)
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    let opacity: Double
}

#Preview {
    SplashView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionManager.shared)
}
