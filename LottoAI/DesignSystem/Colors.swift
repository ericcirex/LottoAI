import SwiftUI

/// Lotto AI 配色系统
/// 设计理念: 深邃科技感 × 彩票主题色
/// Powerball = 红色, Mega Millions = 金色
enum AppColors {
    // MARK: - 背景色
    static let deepBlack = Color(hex: "0D0D1A")
    static let spaceBlue = Color(hex: "1A1A2E")
    static let starBlue = Color(hex: "16213E")

    // MARK: - 强调色
    static let gold = Color(hex: "FFD700")        // Mega Millions 主色
    static let darkGold = Color(hex: "B8860B")    // 暗金色
    static let luckyRed = Color(hex: "E63946")    // Powerball 主色
    static let darkRed = Color(hex: "C41E3A")     // 暗红色
    static let techCyan = Color(hex: "4ECDC4")

    // MARK: - 渐变
    static let purpleGlow = LinearGradient(
        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pinkPurple = LinearGradient(
        colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let techBlue = LinearGradient(
        colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldShine = LinearGradient(
        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - 背景渐变
    static let backgroundGradient = LinearGradient(
        colors: [deepBlack, spaceBlue, starBlue],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - 彩球颜色
    enum Ball {
        // 白球
        static let white = Color.white
        // Powerball = 红色
        static let powerball = Color(hex: "E63946")  // 红色 (Powerball)
        // Mega Millions = 金色
        static let megaball = Color(hex: "FFD700")   // 金色 (Megaball)
    }

    // MARK: - 文字颜色
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
