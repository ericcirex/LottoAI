import SwiftUI

struct PredictionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = PredictionViewModel()
    @State private var showPaywall = false
    @State private var showLimitAlert = false

    private var isPremium: Bool {
        subscriptionManager.subscriptionStatus.isPremium
    }

    var body: some View {
        ZStack {
            // 动态背景
            AnimatedPredictionBackground(isActive: viewModel.isGenerating)

            ScrollView {
                VStack(spacing: 24) {
                    // 彩票选择器
                    PredictionLotteryPicker(selection: $appState.selectedLottery)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    // 标题区域
                    PredictionHeader(lottery: appState.selectedLottery)

                    // 免费版限制提示
                    if !isPremium && !viewModel.isGenerating && viewModel.currentPrediction == nil {
                        FreeTierBanner(
                            predictionsUsed: appState.todayPredictionCount,
                            limit: Constants.FreeLimit.dailyPredictions,
                            onUpgrade: { showPaywall = true }
                        )
                    }

                    // 主要内容区域
                    if viewModel.isGenerating {
                        // 加载动画
                        EnhancedLoadingView(
                            messages: viewModel.loadingMessages,
                            lottery: appState.selectedLottery
                        )
                        .frame(minHeight: 350)
                    } else if let prediction = viewModel.currentPrediction {
                        // 预测结果 (带揭晓动画)
                        BallRevealView(
                            prediction: prediction,
                            lottery: appState.selectedLottery,
                            quote: viewModel.todayQuote,
                            onSave: {
                                appState.savePrediction(prediction, lottery: appState.selectedLottery)
                            },
                            onNewPrediction: {
                                viewModel.reset()
                            }
                        )
                    } else {
                        // 开始按钮
                        EnhancedStartCard(
                            lottery: appState.selectedLottery,
                            onStart: {
                                startPrediction()
                            }
                        )
                    }

                    // 历史预测
                    if !viewModel.predictions.isEmpty && !viewModel.isGenerating && viewModel.currentPrediction == nil {
                        PreviousPredictionsSection(
                            predictions: viewModel.predictions,
                            lottery: appState.selectedLottery
                        )
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Daily Limit Reached", isPresented: $showLimitAlert) {
            Button("Upgrade to Premium") {
                showPaywall = true
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Free users can make \(Constants.FreeLimit.dailyPredictions) prediction per day. Upgrade to Premium for unlimited predictions!")
        }
        .onChange(of: appState.selectedLottery) { _ in
            // Reset current prediction when lottery changes
            viewModel.reset()
        }
    }

    private func startPrediction() {
        if appState.canMakePrediction(isPremium: isPremium) {
            Task {
                await viewModel.generatePrediction(for: appState.selectedLottery)
                if !isPremium {
                    appState.incrementPredictionCount()
                }
            }
        } else {
            showLimitAlert = true
        }
    }
}

// MARK: - 免费版限制横幅
struct FreeTierBanner: View {
    let predictionsUsed: Int
    let limit: Int
    let onUpgrade: () -> Void

    var remaining: Int {
        max(0, limit - predictionsUsed)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: remaining > 0 ? "sparkles" : "lock.fill")
                .foregroundColor(remaining > 0 ? AppColors.gold : AppColors.textTertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(remaining > 0 ? "Free Prediction Available" : "Daily Limit Reached")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(remaining > 0 ? "\(remaining) of \(limit) remaining today" : "Come back tomorrow or upgrade")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            if remaining == 0 {
                Button {
                    onUpgrade()
                    HapticManager.selection()
                } label: {
                    Text("Upgrade")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.goldShine)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.spaceBlue.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(remaining > 0 ? AppColors.gold.opacity(0.3) : AppColors.textTertiary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 动态背景
struct AnimatedPredictionBackground: View {
    let isActive: Bool

    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 基础渐变
            AppColors.backgroundGradient
                .ignoresSafeArea()

            // 活跃状态的光效
            if isActive {
                // 旋转光环
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [AppColors.gold.opacity(0.3), AppColors.techCyan.opacity(0.1), AppColors.gold.opacity(0.3)],
                            center: .center
                        ),
                        lineWidth: 100
                    )
                    .frame(width: 400, height: 400)
                    .rotationEffect(.degrees(rotation))
                    .blur(radius: 30)
                    .opacity(0.5)

                // 中心脉冲
                Circle()
                    .fill(AppColors.gold.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseScale)
                    .blur(radius: 40)
            }
        }
        .onAppear {
            if isActive {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.5
                }
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.5
                }
            }
        }
    }
}

// MARK: - 标题
struct PredictionHeader: View {
    let lottery: LotteryType

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.title2)
                    .foregroundColor(AppColors.gold)

                Text("Lucky Numbers")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(lottery.displayName)
                .font(.headline)
                .foregroundColor(lottery.themeColor)

            Text("AI-enhanced • Statistical Analysis")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
    }
}

// MARK: - 增强版开始卡片
struct EnhancedStartCard: View {
    let lottery: LotteryType
    let onStart: () -> Void

    @State private var isPulsing = false
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 1.0

    var body: some View {
        VStack(spacing: 32) {
            // 动态图标区域
            ZStack {
                // 脉冲光环
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(lottery.themeColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 120 + CGFloat(index) * 30, height: 120 + CGFloat(index) * 30)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                        .animation(
                            .easeOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.4),
                            value: ringScale
                        )
                }

                // 发光背景
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [lottery.themeColor.opacity(0.4), lottery.themeColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(isPulsing ? 1.1 : 0.9)

                // 主图标
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, lottery.themeColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: lottery.themeColor.opacity(0.5), radius: 10)
            }
            .frame(height: 180)

            // 说明文字
            VStack(spacing: 8) {
                Text("Discover your lucky numbers")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text("AI-enhanced statistical magic")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            // 开始按钮
            Button(action: {
                HapticManager.mediumImpact()
                onStart()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title3)

                    Text("Generate Numbers")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ZStack {
                        // 发光底层
                        RoundedRectangle(cornerRadius: 16)
                            .fill(lottery.themeColor.opacity(0.3))
                            .blur(radius: 10)

                        // 渐变主体
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [lottery.themeColor, lottery.themeColor.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // 高光边框
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                )
            }
            .scaleEffect(isPulsing ? 1.02 : 1.0)
        }
        .padding(.vertical, 40)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            ringScale = 2.0
            ringOpacity = 0
        }
    }
}

// MARK: - 增强版加载动画
struct EnhancedLoadingView: View {
    let messages: [String]
    let lottery: LotteryType

    @State private var currentMessageIndex = 0
    @State private var progress: Double = 0
    @State private var radarAngle: Double = 0
    @State private var numberMatrix: [[Int]] = []
    @State private var highlightedNumbers: Set<Int> = []

    var body: some View {
        VStack(spacing: 30) {
            // 雷达扫描效果
            ZStack {
                // 外圈
                Circle()
                    .stroke(AppColors.textTertiary.opacity(0.3), lineWidth: 2)
                    .frame(width: 200, height: 200)

                // 网格线
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .stroke(AppColors.textTertiary.opacity(0.1), lineWidth: 1)
                        .frame(width: CGFloat(50 + i * 40), height: CGFloat(50 + i * 40))
                }

                // 数字矩阵
                ForEach(0..<12, id: \.self) { i in
                    let angle = Double(i) * 30 - 90
                    let radius: CGFloat = 70
                    let x = cos(angle * .pi / 180) * radius
                    let y = sin(angle * .pi / 180) * radius
                    let number = (i * 7 + 3) % 69 + 1

                    Text("\(number)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(highlightedNumbers.contains(number) ? lottery.themeColor : AppColors.textTertiary)
                        .scaleEffect(highlightedNumbers.contains(number) ? 1.3 : 1.0)
                        .offset(x: x, y: y)
                }

                // 雷达扫描线
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [lottery.themeColor.opacity(0.8), lottery.themeColor.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: 100)
                    .offset(y: -50)
                    .rotationEffect(.degrees(radarAngle))

                // 扫描尾迹
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(
                        AngularGradient(
                            colors: [lottery.themeColor.opacity(0.3), lottery.themeColor.opacity(0)],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(90)
                        ),
                        lineWidth: 80
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(radarAngle - 90))
            }
            .frame(width: 220, height: 220)

            // 动态消息
            VStack(spacing: 8) {
                if currentMessageIndex < messages.count {
                    Text(messages[currentMessageIndex])
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                        .id(currentMessageIndex)
                }

                // 进度百分比
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(lottery.themeColor)
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.textTertiary.opacity(0.3))
                        .frame(height: 12)

                    // 进度
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [lottery.themeColor, lottery.themeColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)

                    // 发光点
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .offset(x: geometry.size.width * progress - 4)
                        .shadow(color: lottery.themeColor, radius: 5)
                        .opacity(progress > 0.01 ? 1 : 0)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // 雷达旋转
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            radarAngle = 360
        }

        // 进度动画 (非线性，更有仪式感)
        animateProgress()

        // 消息切换
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            if currentMessageIndex < messages.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentMessageIndex += 1
                }
            } else {
                timer.invalidate()
            }
        }

        // 随机高亮数字
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            if progress >= 1.0 {
                timer.invalidate()
                return
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                let randomNum = Int.random(in: 1...69)
                if highlightedNumbers.count > 5 {
                    highlightedNumbers.removeFirst()
                }
                highlightedNumbers.insert(randomNum)
            }
        }
    }

    private func animateProgress() {
        // 分阶段进度，营造"分析"感
        let stages: [(Double, Double)] = [
            (0.3, 0.8),   // 快速到30%
            (0.5, 1.0),   // 慢下来
            (0.7, 0.6),   // 再加速
            (0.9, 0.8),   // 接近完成
            (1.0, 0.5)    // 最后冲刺
        ]

        var totalDelay = 0.0
        for (target, duration) in stages {
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                withAnimation(.easeInOut(duration: duration)) {
                    progress = target
                }
            }
            totalDelay += duration
        }
    }
}

// MARK: - 球揭晓动画视图
struct BallRevealView: View {
    let prediction: Prediction
    let lottery: LotteryType
    let quote: Quote?
    let onSave: () -> Void
    let onNewPrediction: () -> Void

    @State private var revealedBalls: [Int?] = Array(repeating: nil, count: 5)
    @State private var revealedSpecial: Int?
    @State private var showResult = false
    @State private var showActions = false
    @State private var celebrationParticles = false
    @State private var isSaved = false

    var body: some View {
        VStack(spacing: 24) {
            // 标题
            if showResult {
                Text("Your Lucky Numbers")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.gold)
                    .transition(.scale.combined(with: .opacity))
            }

            // 彩球区域
            HStack(spacing: 10) {
                // 主号码
                ForEach(0..<5, id: \.self) { index in
                    BallRevealCell(
                        number: revealedBalls[index],
                        type: .white,
                        size: 52
                    )
                }

                // 分隔线
                if revealedSpecial != nil {
                    Rectangle()
                        .fill(AppColors.textTertiary)
                        .frame(width: 2, height: 40)
                        .transition(.opacity)
                }

                // 特殊号码
                BallRevealCell(
                    number: revealedSpecial,
                    type: lottery == .powerball ? .powerball : .megaball,
                    size: 52
                )
            }

            // 结果信息
            if showResult {
                VStack(spacing: 16) {
                    // 策略标签
                    HStack {
                        Label(prediction.strategy.displayName, systemImage: prediction.strategy.iconName)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption)
                            Text(prediction.confidenceDisplay)
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(AppColors.techCyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppColors.techCyan.opacity(0.2))
                        )
                    }
                    .padding(.horizontal)

                    Divider()
                        .background(AppColors.textTertiary)

                    // 每日金句
                    if let quote = quote {
                        VStack(spacing: 8) {
                            Text("\"\(quote.text)\"")
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)

                            if let author = quote.author {
                                Text("- \(author)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // 操作按钮
            if showActions {
                HStack(spacing: 16) {
                    Button {
                        if !isSaved {
                            HapticManager.success()
                            onSave()
                            withAnimation(.spring(response: 0.3)) {
                                isSaved = true
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
                            Text(isSaved ? "Saved" : "Save")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSaved ? .white : AppColors.luckyRed)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSaved ? AppColors.luckyRed : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.luckyRed.opacity(0.5), lineWidth: isSaved ? 0 : 1)
                                )
                        )
                    }
                    .disabled(isSaved)

                    Button {
                        sharePrediction()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.gold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.gold.opacity(0.5), lineWidth: 1)
                        )
                    }

                    Button {
                        HapticManager.mediumImpact()
                        onNewPrediction()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("New")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(lottery.themeColor)
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.gold.opacity(0.5), AppColors.gold.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: AppColors.gold.opacity(0.2), radius: 20)
        )
        .onAppear {
            startRevealSequence()
        }
    }

    private func startRevealSequence() {
        // 逐个揭晓主号码
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    revealedBalls[i] = prediction.numbers[i]
                }
                HapticManager.mediumImpact()
            }
        }

        // 揭晓特殊号码 (更长延迟，更强反馈)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                revealedSpecial = prediction.specialBall
            }
            HapticManager.heavyImpact()

            // 短暂延迟后显示结果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showResult = true
                }
                HapticManager.success()

                // 显示操作按钮
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showActions = true
                    }
                }
            }
        }
    }

    private func sharePrediction() {
        let numbers = prediction.numbers.map { String($0) }.joined(separator: " - ")
        let special = lottery == .powerball ? "PB" : "MB"
        let text = """
        🎱 My Numbers from Lotto AI

        \(lottery.displayName)
        \(numbers) | \(special): \(prediction.specialBall)

        Generated using: \(prediction.strategy.displayName)

        Try Lotto AI - Smart Number Generator!
        (For entertainment purposes only)
        """

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - 单个球揭晓单元
struct BallRevealCell: View {
    let number: Int?
    let type: BallType
    let size: CGFloat

    var body: some View {
        ZStack {
            if let num = number {
                // 已揭晓
                LottoBall(number: num, type: type, size: size)
                    .transition(.scale.combined(with: .opacity))
            } else {
                // 未揭晓 - 占位符
                Circle()
                    .fill(AppColors.spaceBlue)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(AppColors.textTertiary.opacity(0.5), lineWidth: 2)
                    )
                    .overlay(
                        Text("?")
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundColor(AppColors.textTertiary)
                    )
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 历史预测区域
struct PreviousPredictionsSection: View {
    let predictions: [Prediction]
    let lottery: LotteryType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Predictions")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)

            ForEach(predictions.prefix(3)) { prediction in
                GlassCard(padding: 12) {
                    HStack {
                        // 小号彩球
                        HStack(spacing: 4) {
                            ForEach(prediction.numbers, id: \.self) { num in
                                Text("\(num)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(AppColors.spaceBlue))
                            }

                            Text("\(prediction.specialBall)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(lottery.themeColor))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(prediction.strategy.displayName)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)

                            Text(prediction.confidenceDisplay)
                                .font(.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 预测页彩票选择器
struct PredictionLotteryPicker: View {
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
                    HStack(spacing: 6) {
                        Circle()
                            .fill(lottery.themeColor)
                            .frame(width: 8, height: 8)

                        Text(lottery.displayName)
                            .font(.subheadline)
                            .fontWeight(selection == lottery ? .bold : .medium)
                    }
                    .foregroundColor(selection == lottery ? .white : AppColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selection == lottery ? lottery.themeColor.opacity(0.3) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selection == lottery ? lottery.themeColor : AppColors.textTertiary.opacity(0.5),
                                        lineWidth: selection == lottery ? 2 : 1
                                    )
                            )
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PredictionView()
            .environmentObject(AppState())
            .environmentObject(SubscriptionManager.shared)
    }
    .preferredColorScheme(.dark)
}
