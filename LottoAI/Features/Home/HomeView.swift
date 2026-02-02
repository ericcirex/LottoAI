import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                AppColors.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 彩票切换
                        LotteryPicker(selection: $appState.selectedLottery)
                            .padding(.horizontal)

                        // 下期开奖倒计时
                        CountdownCard(lottery: appState.selectedLottery)
                            .padding(.horizontal)

                        // Jackpot 金额 (带动画)
                        AnimatedJackpotCard(
                            amount: viewModel.jackpotAmount,
                            lottery: appState.selectedLottery
                        )
                        .padding(.horizontal)

                        // 最新开奖结果
                        if let latestResult = viewModel.latestResult {
                            LatestResultCard(
                                result: latestResult,
                                lottery: appState.selectedLottery
                            )
                            .padding(.horizontal)
                        }

                        // 每日金句 (如果有)
                        if let quote = viewModel.todayQuote {
                            DailyQuoteCard(quote: quote)
                                .padding(.horizontal)
                        }

                        // 快速生成按钮
                        NavigationLink(destination: PredictionView()) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Get Lucky Numbers")
                            }
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AppColors.gold.opacity(0.3))
                                        .blur(radius: 10)

                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AppColors.goldShine)

                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Lotto AI")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            await viewModel.loadData(for: appState.selectedLottery)
        }
        .onChange(of: appState.selectedLottery) { newValue in
            Task {
                await viewModel.loadData(for: newValue)
            }
        }
    }
}

// MARK: - 彩票选择器
struct LotteryPicker: View {
    @Binding var selection: LotteryType

    var body: some View {
        HStack(spacing: 12) {
            ForEach(LotteryType.allCases) { lottery in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = lottery
                    }
                    HapticManager.selection()
                } label: {
                    HStack {
                        Image(systemName: lottery.iconName)
                        Text(lottery.displayName)
                    }
                    .font(.subheadline)
                    .fontWeight(selection == lottery ? .bold : .medium)
                    .foregroundColor(selection == lottery ? .white : AppColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selection == lottery ? lottery.themeColor : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selection == lottery ? Color.clear : AppColors.textTertiary,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
    }
}

// MARK: - 倒计时卡片
struct CountdownCard: View {
    let lottery: LotteryType
    @State private var timeRemaining: TimeInterval = 0
    @State private var nextDrawDate: Date?
    @State private var timer: Timer?

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Draw")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)

                        if let nextDraw = nextDrawDate {
                            Text(formatDrawDate(nextDraw))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary)
                        } else {
                            Text(lottery.drawSchedule)
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }

                    Spacer()

                    // 倒计时显示
                    HStack(spacing: 4) {
                        CountdownUnit(value: days, label: "D", highlight: days > 0)
                        Text(":")
                            .foregroundColor(AppColors.gold)
                            .opacity(days > 0 ? 1 : 0.3)
                        CountdownUnit(value: hours, label: "H", highlight: true)
                        Text(":")
                            .foregroundColor(AppColors.gold)
                        CountdownUnit(value: minutes, label: "M", highlight: true)
                        Text(":")
                            .foregroundColor(AppColors.gold)
                        CountdownUnit(value: seconds, label: "S", highlight: true)
                    }
                }

                // 进度条
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppColors.textTertiary.opacity(0.3))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(lottery.themeColor)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
        .onChange(of: lottery) { _ in
            calculateNextDraw()
        }
    }

    private var days: Int { Int(timeRemaining) / 86400 }
    private var hours: Int { (Int(timeRemaining) % 86400) / 3600 }
    private var minutes: Int { (Int(timeRemaining) % 3600) / 60 }
    private var seconds: Int { Int(timeRemaining) % 60 }

    // 倒计时进度 (0-1)
    private var progress: Double {
        // 假设最大周期为7天
        let maxInterval: TimeInterval = 7 * 24 * 3600
        return max(0, min(1, 1 - (timeRemaining / maxInterval)))
    }

    private func startTimer() {
        calculateNextDraw()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let next = nextDrawDate {
                timeRemaining = max(0, next.timeIntervalSinceNow)
                if timeRemaining <= 0 {
                    // 开奖时间到，重新计算
                    calculateNextDraw()
                }
            }
        }
    }

    private func calculateNextDraw() {
        let calendar = Calendar.current
        let now = Date()

        // 开奖时间 (ET 时区)
        let etTimeZone = TimeZone(identifier: "America/New_York")!
        let components = calendar.dateComponents(in: etTimeZone, from: now)

        // 根据彩票类型确定开奖日
        // Powerball: Mon(2), Wed(4), Sat(7) at 22:59
        // Mega Millions: Tue(3), Fri(6) at 23:00
        let drawDays = lottery.drawDays
        let drawHour = lottery == .powerball ? 22 : 23
        let drawMinute = lottery == .powerball ? 59 : 0

        // 找到下一个开奖日
        for dayOffset in 0...7 {
            var futureComponents = components
            futureComponents.day = (components.day ?? 1) + dayOffset
            futureComponents.hour = drawHour
            futureComponents.minute = drawMinute
            futureComponents.second = 0

            if let futureDate = calendar.date(from: futureComponents) {
                let weekday = calendar.component(.weekday, from: futureDate)
                if drawDays.contains(weekday) && futureDate > now {
                    nextDrawDate = futureDate
                    timeRemaining = futureDate.timeIntervalSinceNow
                    return
                }
            }
        }

        // 默认显示
        timeRemaining = 86400 * 2
    }

    private func formatDrawDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: date) + " ET"
    }
}

// MARK: - 倒计时单元
struct CountdownUnit: View {
    let value: Int
    let label: String
    var highlight: Bool = true

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(highlight ? AppColors.gold : AppColors.textTertiary)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(minWidth: 32)
    }
}

// MARK: - 时间单位
struct TimeUnit: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.gold)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
    }
}

// MARK: - Jackpot 卡片 (带动画)
struct AnimatedJackpotCard: View {
    let amount: String
    let lottery: LotteryType

    @State private var displayedAmount: String = "$0"
    @State private var isAnimating = false

    var body: some View {
        GlowCard(glowColor: lottery.themeColor) {
            HStack {
                // 金币图标 (带脉冲动画)
                ZStack {
                    Circle()
                        .fill(lottery.themeColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0 : 0.5)

                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(lottery.themeColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated Jackpot")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(displayedAmount)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(lottery.themeColor)
                        .contentTransition(.numericText())
                }

                Spacer()

                // 趋势指示
                VStack {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(AppColors.techCyan)
                    Text("Rising")
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .onAppear {
            // 数字滚动动画
            withAnimation(.easeOut(duration: 1.5)) {
                displayedAmount = amount
            }
            // 脉冲动画
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
        .onChange(of: amount) { newValue in
            withAnimation(.easeOut(duration: 0.8)) {
                displayedAmount = newValue
            }
        }
    }
}

// MARK: - 每日金句卡片
struct DailyQuoteCard: View {
    let quote: Quote

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Text(quote.category.emoji)
                        .font(.title2)

                    Text("Daily Fortune")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.gold)

                    Spacer()

                    Text(quote.category.displayName)
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppColors.spaceBlue)
                        )
                }

                Text("\"\(quote.text)\"")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                if let author = quote.author {
                    Text("- \(author)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

// MARK: - 旧版 Jackpot 卡片 (保留兼容)
struct JackpotCard: View {
    let amount: String
    let lottery: LotteryType

    var body: some View {
        AnimatedJackpotCard(amount: amount, lottery: lottery)
    }
}

// MARK: - 最新开奖卡片
struct LatestResultCard: View {
    let result: DrawResult
    let lottery: LotteryType

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Latest Draw")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Text(result.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }

                LottoBallRow(
                    mainNumbers: result.numbers,
                    specialNumber: result.specialBall,
                    lotteryType: lottery,
                    ballSize: 44
                )
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
