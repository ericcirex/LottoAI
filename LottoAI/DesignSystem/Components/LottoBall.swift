import SwiftUI

/// 彩球类型
enum BallType {
    case white           // 普通白球
    case powerball       // Powerball 红球
    case megaball        // Mega Millions 金球

    var gradientColors: [Color] {
        switch self {
        case .white:
            return [Color.white, Color(hex: "E8E8E8")]
        case .powerball:
            return [Color(hex: "E63946"), Color(hex: "C41E3A")]  // 红色
        case .megaball:
            return [Color(hex: "FFD700"), Color(hex: "FFA500")]  // 金色
        }
    }

    var shadowColor: Color {
        switch self {
        case .white:
            return Color.black.opacity(0.3)
        case .powerball:
            return Color(hex: "C41E3A").opacity(0.5)
        case .megaball:
            return Color(hex: "FFD700").opacity(0.5)
        }
    }

    var textColor: Color {
        switch self {
        case .white:
            return Color(hex: "1A1A2E")
        case .powerball, .megaball:
            return Color.white
        }
    }
}

/// 3D 立体彩球组件
struct LottoBall: View {
    let number: Int
    let type: BallType
    var size: CGFloat = 56
    var animated: Bool = false
    var animationDelay: Double = 0

    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            // 球体主体 - 3D 渐变效果
            Circle()
                .fill(
                    RadialGradient(
                        colors: type.gradientColors,
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .shadow(color: type.shadowColor, radius: 8, x: 0, y: 4)

            // 高光效果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.6), Color.clear],
                        center: UnitPoint(x: 0.3, y: 0.2),
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )

            // 数字
            Text("\(number)")
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(type.textColor)
        }
        .frame(width: size, height: size)
        .scaleEffect(animated ? (hasAppeared ? 1.0 : 0.8) : 1.0)
        .opacity(animated ? (hasAppeared ? 1.0 : 0) : 1.0)
        .onAppear {
            if animated {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(animationDelay)) {
                    hasAppeared = true
                }
            }
        }
    }
}

/// 彩球行组件 - 显示一组号码
struct LottoBallRow: View {
    let mainNumbers: [Int]
    let specialNumber: Int
    let lotteryType: LotteryType
    var ballSize: CGFloat = 48

    var body: some View {
        HStack(spacing: 8) {
            // 主号码
            ForEach(mainNumbers, id: \.self) { number in
                LottoBall(number: number, type: .white, size: ballSize)
            }

            // 分隔
            Rectangle()
                .fill(AppColors.textTertiary)
                .frame(width: 1, height: ballSize * 0.6)
                .padding(.horizontal, 4)

            // 特殊号码
            LottoBall(
                number: specialNumber,
                type: lotteryType == .powerball ? .powerball : .megaball,
                size: ballSize
            )
        }
    }
}

#Preview("Single Ball") {
    VStack(spacing: 20) {
        LottoBall(number: 21, type: .white)
        LottoBall(number: 11, type: .powerball)
        LottoBall(number: 5, type: .megaball)
    }
    .padding()
    .background(AppColors.spaceBlue)
}

#Preview("Ball Row") {
    VStack(spacing: 20) {
        LottoBallRow(
            mainNumbers: [12, 24, 37, 45, 68],
            specialNumber: 11,
            lotteryType: .powerball
        )

        LottoBallRow(
            mainNumbers: [5, 18, 33, 42, 61],
            specialNumber: 22,
            lotteryType: .megaMillions
        )
    }
    .padding()
    .background(AppColors.spaceBlue)
}
