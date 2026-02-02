import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var onSuccess: (() -> Void)?

    var body: some View {
        ZStack {
            // 背景
            AppColors.backgroundGradient
                .ignoresSafeArea()

            // 装饰元素
            GeometryReader { geometry in
                Circle()
                    .fill(AppColors.gold.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -50)

                Circle()
                    .fill(AppColors.luckyRed.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)
            }

            VStack(spacing: 40) {
                Spacer()

                // Logo 和标题
                VStack(spacing: 20) {
                    // Logo
                    ZStack {
                        Circle()
                            .fill(AppColors.gold.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.gold, Color(hex: "FFA500")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("Lotto AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Your Lucky Numbers Await")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                // 功能亮点
                VStack(spacing: 16) {
                    FeatureRow(icon: "wand.and.stars", text: "AI-Powered Predictions")
                    FeatureRow(icon: "camera.fill", text: "Scan & Check Tickets")
                    FeatureRow(icon: "bell.badge.fill", text: "Instant Draw Notifications")
                    FeatureRow(icon: "chart.bar.fill", text: "Hot & Cold Number Analysis")
                }
                .padding(.horizontal, 40)

                Spacer()

                // 登录按钮
                VStack(spacing: 16) {
                    // Apple Sign-In 按钮
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        // 使用 AuthenticationManager 处理
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .overlay(
                        Group {
                            if isLoading {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.5))
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                    )
                    .disabled(isLoading)
                    .onTapGesture {
                        signInWithApple()
                    }

                    // 或者使用自定义按钮
                    Button {
                        signInWithApple()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.title2)
                            Text("Continue with Apple")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    .disabled(isLoading)

                    // 跳过登录
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue as Guest")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 24)

                // 条款
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
                    .frame(height: 20)
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func signInWithApple() {
        isLoading = true
        HapticManager.mediumImpact()

        Task {
            do {
                _ = try await authManager.signInWithApple()
                HapticManager.success()
                onSuccess?()
                dismiss()
            } catch AuthError.cancelled {
                // 用户取消，不显示错误
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
            isLoading = false
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.gold)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppColors.techCyan)
        }
    }
}

// MARK: - User Profile Header (for logged in users)
struct UserProfileHeader: View {
    let user: AppUser
    @StateObject private var authManager = AuthenticationManager.shared

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.gold, Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Text(user.displayName.prefix(1).uppercased())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundColor(.white)

                if user.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                        Text("Premium Member")
                            .font(.caption)
                    }
                    .foregroundColor(AppColors.gold)
                } else {
                    Text("Free Member")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(user.stats.totalPredictions)")
                        .font(.headline)
                        .foregroundColor(AppColors.gold)
                    Text("predictions")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                if user.stats.ticketsScanned > 0 {
                    HStack(spacing: 4) {
                        Text("\(user.stats.ticketsScanned)")
                            .font(.subheadline)
                            .foregroundColor(AppColors.techCyan)
                        Text("scanned")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.spaceBlue.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.gold.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    LoginView()
        .preferredColorScheme(.dark)
}
