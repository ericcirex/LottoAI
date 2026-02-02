import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var showRestoreSuccess = false
    @State private var showRestoreEmpty = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // 动态背景
            PaywallBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 关闭按钮
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                            HapticManager.lightImpact()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal)

                    // 皇冠动画
                    CrownAnimation()
                        .frame(height: 120)

                    // 标题
                    VStack(spacing: 8) {
                        Text("Go Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.gold, Color(hex: "FFA500")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Unlock the full premium experience")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // 3天免费试用横幅
                    TrialBanner()
                        .padding(.horizontal)

                    // 功能列表
                    PremiumFeaturesList()
                        .padding(.horizontal)

                    // 订阅选项
                    SubscriptionOptions(
                        products: subscriptionManager.products,
                        selectedProduct: $selectedProduct
                    )
                    .padding(.horizontal)

                    // 购买按钮
                    PurchaseButton(
                        isLoading: isPurchasing,
                        isDisabled: selectedProduct == nil
                    ) {
                        Task {
                            await purchase()
                        }
                    }
                    .padding(.horizontal)

                    // 试用期提示
                    if selectedProduct != nil {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(AppColors.techCyan)
                                Text("3-day free trial included")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Text("You won't be charged during the trial period")
                                .font(.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }

                    // 底部链接
                    HStack(spacing: 20) {
                        Button {
                            Task {
                                await restorePurchases()
                            }
                        } label: {
                            if isRestoring {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Text("Restore")
                            }
                        }
                        .disabled(isRestoring)

                        Text("·")

                        Button("Terms") {
                            showTerms = true
                        }

                        Text("·")

                        Button("Privacy") {
                            showPrivacy = true
                        }
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)

                    // 保证文字
                    GuaranteeSection()
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Restore Successful", isPresented: $showRestoreSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your subscription has been restored successfully!")
        }
        .alert("No Purchases Found", isPresented: $showRestoreEmpty) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We couldn't find any previous purchases associated with your account.")
        }
        .sheet(isPresented: $showTerms) {
            TermsView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyView()
        }
    }

    private func purchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        HapticManager.mediumImpact()

        do {
            if let _ = try await subscriptionManager.purchase(product) {
                HapticManager.heavyImpact()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isPurchasing = false
    }

    private func restorePurchases() async {
        isRestoring = true
        HapticManager.lightImpact()

        await subscriptionManager.restorePurchases()

        if subscriptionManager.subscriptionStatus.isPremium {
            HapticManager.success()
            showRestoreSuccess = true
        } else {
            showRestoreEmpty = true
        }

        isRestoring = false
    }
}

// MARK: - 3天免费试用横幅
struct TrialBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.title2)
                .foregroundColor(AppColors.gold)

            VStack(alignment: .leading, spacing: 2) {
                Text("3-Day Free Trial")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Try all premium features risk-free")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Text("FREE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppColors.deepBlack)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppColors.gold)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.gold.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Terms View
struct TermsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Last updated: February 2026")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Group {
                        Text("1. Acceptance of Terms")
                            .font(.headline)
                        Text("By using Lotto AI, you agree to these terms. This app is for entertainment purposes only and does not guarantee any lottery winnings.")

                        Text("2. Entertainment Purpose")
                            .font(.headline)
                        Text("Lotto AI provides number suggestions based on statistical analysis and randomization. These suggestions are purely for entertainment and should not be considered as predictions of lottery outcomes.")

                        Text("3. Subscriptions")
                            .font(.headline)
                        Text("Premium subscriptions are billed through your Apple ID account. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. You can manage subscriptions in your Apple ID settings.")

                        Text("4. Free Trial")
                            .font(.headline)
                        Text("New subscribers may be eligible for a 3-day free trial. If you don't cancel before the trial ends, you will be automatically charged the subscription fee.")

                        Text("5. Refunds")
                            .font(.headline)
                        Text("For refund requests, please contact Apple Support as all payments are processed through the App Store.")

                        Text("6. Disclaimer")
                            .font(.headline)
                        Text("Lotto AI does not claim to predict lottery results. Lottery games are games of chance, and no app can guarantee winning numbers. Please gamble responsibly.")
                    }
                }
                .padding()
            }
            .background(AppColors.backgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Privacy View
struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Last updated: February 2026")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Group {
                        Text("1. Information We Collect")
                            .font(.headline)
                        Text("Lotto AI collects minimal data. We do not collect personal information, lottery tickets, or financial data. Usage analytics may be collected anonymously to improve the app experience.")

                        Text("2. Data Storage")
                            .font(.headline)
                        Text("Your saved predictions and preferences are stored locally on your device. We do not upload your data to external servers.")

                        Text("3. Third-Party Services")
                            .font(.headline)
                        Text("We use Apple's StoreKit for subscription management. Apple's privacy policy applies to subscription transactions.")

                        Text("4. Notifications")
                            .font(.headline)
                        Text("If you enable notifications, we may send you draw reminders and app updates. You can disable notifications at any time in your device settings.")

                        Text("5. Children's Privacy")
                            .font(.headline)
                        Text("Lotto AI is intended for users 17 years of age and older. We do not knowingly collect information from children.")

                        Text("6. Contact")
                            .font(.headline)
                        Text("For privacy-related questions, please contact us through the App Store support link.")
                    }
                }
                .padding()
            }
            .background(AppColors.backgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 动态背景
struct PaywallBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            AppColors.backgroundGradient

            // 动态光效
            Circle()
                .fill(AppColors.gold.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: sin(phase) * 50, y: cos(phase) * 30 - 100)

            Circle()
                .fill(Color(hex: "667eea").opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: cos(phase * 0.8) * 40 + 100, y: sin(phase * 0.8) * 40 + 200)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - 皇冠动画
struct CrownAnimation: View {
    @State private var isAnimating = false
    @State private var sparkles: [SparkleItem] = []

    var body: some View {
        ZStack {
            // 光晕
            Circle()
                .fill(AppColors.gold.opacity(0.2))
                .frame(width: 100, height: 100)
                .scaleEffect(isAnimating ? 1.3 : 1)
                .opacity(isAnimating ? 0 : 0.5)

            Circle()
                .fill(AppColors.gold.opacity(0.15))
                .frame(width: 100, height: 100)
                .scaleEffect(isAnimating ? 1.5 : 1)
                .opacity(isAnimating ? 0 : 0.3)

            // 皇冠
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.gold, Color(hex: "FFA500"), AppColors.gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AppColors.gold.opacity(0.5), radius: 20)

            // 闪烁粒子
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundColor(AppColors.gold)
                    .offset(x: sparkle.x, y: sparkle.y)
                    .opacity(sparkle.opacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
            startSparkles()
        }
    }

    private func startSparkles() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            let sparkle = SparkleItem(
                id: UUID(),
                x: CGFloat.random(in: -60...60),
                y: CGFloat.random(in: -60...60),
                size: CGFloat.random(in: 8...14),
                opacity: 1
            )
            sparkles.append(sparkle)

            withAnimation(.easeOut(duration: 0.8)) {
                if let index = sparkles.firstIndex(where: { $0.id == sparkle.id }) {
                    sparkles[index].opacity = 0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                sparkles.removeAll { $0.id == sparkle.id }
            }
        }
    }
}

struct SparkleItem: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    var opacity: Double
}

// MARK: - 功能列表
struct PremiumFeaturesList: View {
    let features: [(String, String, String)] = [
        ("wand.and.stars", "AI-Enhanced Analysis", "Smart number suggestions powered by AI"),
        ("sparkles", "Premium Rituals", "Beautiful reveal animations & effects"),
        ("flame.fill", "Hot & Cold Insights", "Discover trending number patterns"),
        ("heart.fill", "Save Favorites", "Keep your lucky combinations"),
        ("bell.badge.fill", "Draw Reminders", "Never miss a jackpot draw"),
        ("quote.bubble.fill", "Daily Fortune", "Inspiring quotes & lucky insights")
    ]

    @State private var visibleItems: Set<Int> = []

    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppColors.gold.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: feature.0)
                                .font(.body)
                                .foregroundColor(AppColors.gold)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.1)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)

                            Text(feature.2)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.techCyan)
                    }
                    .opacity(visibleItems.contains(index) ? 1 : 0)
                    .offset(x: visibleItems.contains(index) ? 0 : 20)
                }
            }
        }
        .onAppear {
            for i in 0..<features.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        _ = visibleItems.insert(i)
                    }
                }
            }
        }
    }
}

// MARK: - 订阅选项
struct SubscriptionOptions: View {
    let products: [Product]
    @Binding var selectedProduct: Product?

    // 备用价格显示 (当 StoreKit 产品未加载时)
    private let fallbackPrices: [String: (price: String, period: String)] = [
        "weekly": ("$3.99", "per week"),
        "monthly": ("$11.99", "per month"),
        "yearly": ("$89.99", "per year")
    ]

    var body: some View {
        HStack(spacing: 12) {
            // 如果 StoreKit 产品已加载，使用实际产品
            if !products.isEmpty {
                ForEach(products, id: \.id) { product in
                    SubscriptionCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        isPopular: product.id.contains("monthly"),
                        savings: calculateSavings(product)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedProduct = product
                        }
                        HapticManager.selection()
                    }
                }
            } else {
                // 备用显示：当产品未加载时显示占位卡片
                FallbackSubscriptionCard(
                    title: "Weekly",
                    price: "$3.99",
                    period: "per week",
                    isPopular: false,
                    savings: nil
                )
                FallbackSubscriptionCard(
                    title: "Monthly",
                    price: "$11.99",
                    period: "per month",
                    isPopular: true,
                    savings: nil
                )
                FallbackSubscriptionCard(
                    title: "Yearly",
                    price: "$89.99",
                    period: "per year",
                    isPopular: false,
                    savings: "Save 38%"
                )
            }
        }
        .onAppear {
            if selectedProduct == nil {
                selectedProduct = products.first { $0.id.contains("monthly") } ?? products.first
            }
        }
    }

    private func calculateSavings(_ product: Product) -> String? {
        if product.id.contains("yearly") {
            return "Save 38%"
        }
        return nil
    }
}

// MARK: - 备用订阅卡片 (产品未加载时)
struct FallbackSubscriptionCard: View {
    let title: String
    let price: String
    let period: String
    let isPopular: Bool
    let savings: String?

    var body: some View {
        VStack(spacing: 8) {
            if isPopular {
                Text("MOST POPULAR")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.deepBlack)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppColors.gold)
                    )
            } else {
                Spacer()
                    .frame(height: 20)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)

            Text(price)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(period)
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)

            if let savings = savings {
                Text(savings)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.techCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(AppColors.techCyan.opacity(0.2))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.deepBlack.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.textTertiary, lineWidth: 1)
                )
        )
    }
}

// MARK: - 订阅卡片
struct SubscriptionCard: View {
    let product: Product
    let isSelected: Bool
    let isPopular: Bool
    let savings: String?
    let onSelect: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(spacing: 8) {
                if isPopular {
                    Text("MOST POPULAR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.deepBlack)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppColors.gold)
                        )
                } else {
                    Spacer()
                        .frame(height: 20)
                }

                Text(periodName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textSecondary)

                Text(product.displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? AppColors.gold : .white)

                Text(perPeriod)
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)

                if let savings = savings {
                    Text(savings)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.techCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(AppColors.techCyan.opacity(0.2))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppColors.spaceBlue : AppColors.deepBlack.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected
                                    ? LinearGradient(colors: [AppColors.gold, Color(hex: "FFA500")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [AppColors.textTertiary], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var periodName: String {
        if product.id.contains("weekly") { return "Weekly" }
        if product.id.contains("monthly") { return "Monthly" }
        if product.id.contains("yearly") { return "Yearly" }
        return "Plan"
    }

    private var perPeriod: String {
        if product.id.contains("weekly") { return "per week" }
        if product.id.contains("monthly") { return "per month" }
        if product.id.contains("yearly") { return "per year" }
        return ""
    }
}

// MARK: - 购买按钮
struct PurchaseButton: View {
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isAnimating = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // 光晕背景
                if !isDisabled {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.gold.opacity(0.3))
                        .blur(radius: 10)
                        .scaleEffect(isAnimating ? 1.05 : 1)
                }

                // 主按钮
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "crown.fill")
                        Text("Start Free Trial")
                    }
                }
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isDisabled ? AppColors.textTertiary : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isDisabled
                                ? AnyShapeStyle(AppColors.spaceBlue)
                                : AnyShapeStyle(AppColors.goldShine)
                        )
                )
            }
        }
        .disabled(isDisabled || isLoading)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - 保证区域
struct GuaranteeSection: View {
    var body: some View {
        HStack(spacing: 24) {
            GuaranteeItem(icon: "lock.shield.fill", text: "Secure")
            GuaranteeItem(icon: "arrow.clockwise", text: "Cancel Anytime")
            GuaranteeItem(icon: "dollarsign.circle.fill", text: "Refund OK")
        }
    }
}

struct GuaranteeItem: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.textTertiary)

            Text(text)
                .font(.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
    }
}

#Preview {
    PaywallView()
        .preferredColorScheme(.dark)
}
