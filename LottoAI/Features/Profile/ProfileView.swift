import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showPaywall = false
    @State private var showSavedPredictions = false
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showDisclaimer = false
    @State private var showLogin = false
    @State private var showScanner = false
    @State private var showSignOutConfirm = false
    @State private var showScannedTickets = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 用户卡片 / 登录提示
                    if let user = authManager.currentUser {
                        VStack(spacing: 12) {
                            UserProfileHeader(user: user)

                            // Sign Out 按钮
                            Button {
                                showSignOutConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                                .font(.subheadline)
                                .foregroundColor(AppColors.luckyRed)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        LoginPromptCard(onLogin: { showLogin = true })
                            .padding(.horizontal)
                    }

                    // 订阅状态卡片
                    SubscriptionStatusCard(
                        status: subscriptionManager.subscriptionStatus,
                        onUpgrade: { showPaywall = true }
                    )
                    .padding(.horizontal)

                    // 功能菜单
                    VStack(spacing: 1) {
                        // 扫描彩票
                        MenuRow(
                            icon: "camera.viewfinder",
                            title: "Scan Ticket",
                            badge: nil,
                            color: AppColors.gold
                        ) {
                            showScanner = true
                        }

                        // 扫描历史
                        if authManager.isAuthenticated {
                            MenuRow(
                                icon: "ticket",
                                title: "Scanned Tickets",
                                badge: nil,
                                color: AppColors.techCyan
                            ) {
                                showScannedTickets = true
                            }
                        }

                        MenuRow(
                            icon: "heart.fill",
                            title: "Saved Predictions",
                            badge: appState.savedPredictions.count > 0 ? "\(appState.savedPredictions.count)" : nil,
                            color: AppColors.luckyRed
                        ) {
                            showSavedPredictions = true
                        }

                        MenuRow(icon: "bell.fill", title: "Notifications", color: AppColors.gold) {
                            openNotificationSettings()
                        }

                        MenuRow(icon: "paintbrush.fill", title: "Appearance", color: AppColors.techCyan) {
                            showSettings = true
                        }
                    }
                    .background(AppColors.spaceBlue.opacity(0.5))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // 使用统计
                    UsageStatsCard(
                        isPremium: subscriptionManager.subscriptionStatus.isPremium,
                        predictionsToday: appState.todayPredictionCount
                    )
                    .padding(.horizontal)

                    // 关于和法律
                    VStack(spacing: 1) {
                        MenuRow(icon: "info.circle.fill", title: "About Lotto AI", color: AppColors.textSecondary) {
                            showAbout = true
                        }

                        MenuRow(icon: "doc.text.fill", title: "Privacy Policy", color: AppColors.textSecondary) {
                            openPrivacyPolicy()
                        }

                        MenuRow(icon: "doc.text.fill", title: "Terms of Use", color: AppColors.textSecondary) {
                            openTermsOfUse()
                        }

                        MenuRow(icon: "exclamationmark.triangle.fill", title: "Disclaimer", color: AppColors.gold) {
                            showDisclaimer = true
                        }
                    }
                    .background(AppColors.spaceBlue.opacity(0.5))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // 版本信息
                    VStack(spacing: 4) {
                        Text("Lotto AI")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textSecondary)

                        Text("Version \(appVersion)")
                            .font(.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.top, 20)

                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .background(AppColors.backgroundGradient.ignoresSafeArea())
            .navigationDestination(isPresented: $showSavedPredictions) {
                SavedPredictionsView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showScannedTickets) {
                ScannedTicketsView()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showDisclaimer) {
            DisclaimerView()
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
        .fullScreenCover(isPresented: $showScanner) {
            TicketScannerView()
        }
        .confirmationDialog("Sign Out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
                HapticManager.mediumImpact()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your local data will be preserved, but you'll need to sign in again to sync across devices.")
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://ericcirex.github.io/lotto-ai-api/privacy") {
            UIApplication.shared.open(url)
        }
    }

    private func openTermsOfUse() {
        if let url = URL(string: "https://ericcirex.github.io/lotto-ai-api/terms") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 订阅状态卡片
struct SubscriptionStatusCard: View {
    let status: SubscriptionStatus
    let onUpgrade: () -> Void

    @State private var isAnimating = false

    var body: some View {
        GlowCard(glowColor: status.isPremium ? AppColors.gold : Color(hex: "667eea")) {
            VStack(spacing: 16) {
                HStack {
                    // 订阅图标
                    ZStack {
                        Circle()
                            .fill(status.isPremium ? AppColors.gold.opacity(0.2) : AppColors.spaceBlue)
                            .frame(width: 56, height: 56)

                        if status.isPremium {
                            Circle()
                                .fill(AppColors.gold.opacity(0.1))
                                .frame(width: 56, height: 56)
                                .scaleEffect(isAnimating ? 1.3 : 1)
                                .opacity(isAnimating ? 0 : 0.5)
                        }

                        Image(systemName: status.isPremium ? "crown.fill" : "lock.fill")
                            .font(.title2)
                            .foregroundColor(status.isPremium ? AppColors.gold : AppColors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(status.isPremium ? "Premium Member" : "Free Plan")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(status.displayText)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    if status.isPremium {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.gold)
                    }
                }

                if !status.isPremium {
                    Button {
                        onUpgrade()
                        HapticManager.mediumImpact()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Upgrade to Premium")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    }
                    .glowStyle()
                }
            }
        }
        .onAppear {
            if status.isPremium {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - 使用统计卡片
struct UsageStatsCard: View {
    let isPremium: Bool
    let predictionsToday: Int

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Text("Today's Usage")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    Spacer()

                    if isPremium {
                        Text("Unlimited")
                            .font(.caption)
                            .foregroundColor(AppColors.gold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.gold.opacity(0.2))
                            .cornerRadius(8)
                    }
                }

                HStack(spacing: 20) {
                    UsageItem(
                        icon: "brain.head.profile",
                        value: isPremium ? "∞" : "\(predictionsToday)/\(Constants.FreeLimit.dailyPredictions)",
                        label: "Predictions"
                    )

                    Divider()
                        .frame(height: 40)
                        .background(AppColors.textTertiary)

                    UsageItem(
                        icon: "chart.bar.fill",
                        value: isPremium ? "5" : "1",
                        label: "Strategies"
                    )

                    Divider()
                        .frame(height: 40)
                        .background(AppColors.textTertiary)

                    UsageItem(
                        icon: "clock.fill",
                        value: isPremium ? "∞" : "\(Constants.FreeLimit.historyCount)",
                        label: "History"
                    )
                }
            }
        }
    }
}

struct UsageItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.techCyan)

            Text(value)
                .font(.headline)
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 菜单行
struct MenuRow: View {
    let icon: String
    let title: String
    var badge: String? = nil
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticManager.selection()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32)

                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Spacer()

                if let badge = badge {
                    Text(badge)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.3))
                        .cornerRadius(8)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding()
            .background(AppColors.spaceBlue.opacity(0.3))
        }
    }
}

// MARK: - 保存的预测视图
struct SavedPredictionsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            if appState.savedPredictions.isEmpty {
                EmptyStateView(
                    icon: "heart.slash",
                    title: "No Saved Predictions",
                    subtitle: "Save your favorite predictions to view them here"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(appState.savedPredictions) { saved in
                            SavedPredictionCard(saved: saved) {
                                appState.deletePrediction(saved)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Saved Predictions")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

struct SavedPredictionCard: View {
    let saved: SavedPrediction
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    // 彩票类型
                    HStack(spacing: 8) {
                        Image(systemName: saved.lottery.iconName)
                            .foregroundColor(saved.lottery.themeColor)
                        Text(saved.lottery.displayName)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text(saved.formattedDate)
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }

                // 号码显示
                LottoBallRow(
                    mainNumbers: saved.prediction.numbers,
                    specialNumber: saved.prediction.specialBall,
                    lotteryType: saved.lottery,
                    ballSize: 40
                )

                // 策略
                HStack {
                    Text("Strategy: \(saved.prediction.strategyName)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(AppColors.luckyRed)
                    }
                }
            }
        }
        .confirmationDialog("Delete Prediction?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - 设置视图
struct SettingsView: View {
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 触感反馈
                    GlassCard {
                        VStack(spacing: 16) {
                            SettingsToggle(
                                icon: "hand.tap.fill",
                                title: "Haptic Feedback",
                                subtitle: "Feel vibrations during interactions",
                                isOn: $hapticEnabled
                            )
                        }
                    }
                    .padding(.horizontal)

                    // 提示
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(AppColors.techCyan)
                                Text("Tip")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }

                            Text("For notification settings, please use the iOS Settings app.")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct SettingsToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.techCyan)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.gold)
        }
    }
}

// MARK: - 关于视图
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 关闭按钮
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal)

                    // Logo
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppColors.goldShine)
                                .frame(width: 100, height: 100)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }

                        Text("Lotto AI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Your Lucky Number Companion")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // 描述
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Lotto AI transforms number selection into an exciting ritual. Using AI-enhanced statistical analysis of historical data, we create a premium experience that makes playing the lottery more engaging and fun.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(4)

                            Text("Enjoy beautiful animations, daily fortune insights, and smart number suggestions. While no method can guarantee winning numbers, we make every moment of anticipation magical.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal)

                    // 功能亮点
                    GlassCard {
                        VStack(spacing: 16) {
                            FeatureHighlight(icon: "wand.and.stars", title: "AI-Enhanced", description: "Smart statistical analysis")
                            FeatureHighlight(icon: "sparkles", title: "Premium Design", description: "Beautiful animations & rituals")
                            FeatureHighlight(icon: "heart.fill", title: "Daily Fortune", description: "Inspiring quotes & insights")
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.gold)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - 免责声明视图
struct DisclaimerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 关闭按钮
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal)

                    // 图标
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.gold)

                    Text("Important Disclaimer")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // 内容
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            DisclaimerItem(
                                number: "1",
                                text: "Lotto AI is for entertainment purposes only. Lottery games are games of chance, and no prediction method can guarantee winning numbers."
                            )

                            DisclaimerItem(
                                number: "2",
                                text: "Our AI predictions are based on historical data analysis and statistical patterns. Past performance does not guarantee future results."
                            )

                            DisclaimerItem(
                                number: "3",
                                text: "Please play responsibly. Never spend more than you can afford to lose, and be aware of the signs of problem gambling."
                            )

                            DisclaimerItem(
                                number: "4",
                                text: "This app is not affiliated with, endorsed by, or connected to any official lottery organization."
                            )
                        }
                    }
                    .padding(.horizontal)

                    // 确认按钮
                    Button {
                        dismiss()
                    } label: {
                        Text("I Understand")
                            .fontWeight(.semibold)
                    }
                    .glowStyle()
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}

struct DisclaimerItem: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppColors.gold.opacity(0.3)))

            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)

            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Login Prompt Card
struct LoginPromptCard: View {
    let onLogin: () -> Void

    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppColors.gold.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title2)
                            .foregroundColor(AppColors.gold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Sync your data across devices")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()
                }

                Button(action: onLogin) {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionManager.shared)
        .preferredColorScheme(.dark)
}
