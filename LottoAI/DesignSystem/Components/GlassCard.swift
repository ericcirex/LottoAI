import SwiftUI

/// 毛玻璃卡片组件
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

/// 带发光效果的卡片
struct GlowCard<Content: View>: View {
    let content: Content
    var glowColor: Color = AppColors.gold
    var cornerRadius: CGFloat = 20

    init(
        glowColor: Color = AppColors.gold,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.glowColor = glowColor
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.spaceBlue.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(glowColor.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: glowColor.opacity(0.3), radius: 15, x: 0, y: 0)
            )
    }
}

#Preview("Glass Card") {
    ZStack {
        AppColors.backgroundGradient
            .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Latest Draw")
                        .font(.headline)
                        .foregroundColor(AppColors.textSecondary)

                    Text("January 29, 2026")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    LottoBallRow(
                        mainNumbers: [12, 24, 37, 45, 68],
                        specialNumber: 11,
                        lotteryType: .powerball,
                        ballSize: 40
                    )
                }
            }

            GlowCard(glowColor: AppColors.gold) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.gold)

                    VStack(alignment: .leading) {
                        Text("Jackpot")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text("$1.9 Billion")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.gold)
                    }

                    Spacer()
                }
            }
        }
        .padding()
    }
}
