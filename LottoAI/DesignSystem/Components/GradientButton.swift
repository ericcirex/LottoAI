import SwiftUI

/// 渐变按钮样式
struct GradientButtonStyle: ButtonStyle {
    var gradient: LinearGradient = AppColors.goldShine
    var cornerRadius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
                    .shadow(color: AppColors.gold.opacity(0.4), radius: 8, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// 发光按钮样式 - 用于主要 CTA
struct GlowButtonStyle: ButtonStyle {
    var color: Color = AppColors.gold
    var cornerRadius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // 发光层
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color.opacity(0.3))
                        .blur(radius: 10)

                    // 主体
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // 内发光边框
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// 轮廓按钮样式
struct OutlineButtonStyle: ButtonStyle {
    var color: Color = AppColors.textSecondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Button Extension
extension Button {
    func gradientStyle(_ gradient: LinearGradient = AppColors.goldShine) -> some View {
        self.buttonStyle(GradientButtonStyle(gradient: gradient))
    }

    func glowStyle(_ color: Color = AppColors.gold) -> some View {
        self.buttonStyle(GlowButtonStyle(color: color))
    }

    func outlineStyle(_ color: Color = AppColors.textSecondary) -> some View {
        self.buttonStyle(OutlineButtonStyle(color: color))
    }
}

#Preview("Buttons") {
    ZStack {
        AppColors.backgroundGradient
            .ignoresSafeArea()

        VStack(spacing: 20) {
            Button("Start AI Prediction") {
                // Action
            }
            .glowStyle()

            Button("Generate Numbers") {
                // Action
            }
            .gradientStyle()

            Button("View History") {
                // Action
            }
            .gradientStyle(AppColors.purpleGlow)

            HStack(spacing: 12) {
                Button("Save") {
                    // Action
                }
                .outlineStyle()

                Button("Share") {
                    // Action
                }
                .outlineStyle(AppColors.gold)
            }
        }
        .padding()
    }
}
