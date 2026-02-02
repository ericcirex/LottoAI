import SwiftUI
import UIKit

/// 触觉反馈管理器
enum HapticManager {
    /// 检查是否启用触感反馈
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticEnabled") as? Bool ?? true
    }

    // MARK: - Impact Feedback

    /// 冲击反馈
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// 轻触
    static func lightImpact() {
        impact(.light)
    }

    /// 中等冲击 - 用于彩球揭晓
    static func mediumImpact() {
        impact(.medium)
    }

    /// 重冲击 - 用于 Powerball 揭晓
    static func heavyImpact() {
        impact(.heavy)
    }

    // MARK: - Notification Feedback

    /// 通知反馈
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    /// 成功反馈 - 预测完成
    static func success() {
        notification(.success)
    }

    /// 警告反馈
    static func warning() {
        notification(.warning)
    }

    /// 错误反馈
    static func error() {
        notification(.error)
    }

    // MARK: - Selection Feedback

    /// 选择反馈 - 切换选项
    static func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - 组合反馈序列

    /// 彩球揭晓序列
    static func ballRevealSequence(count: Int, specialBallDelay: Double = 0.4) async {
        for _ in 0..<count {
            try? await Task.sleep(for: .milliseconds(Int(specialBallDelay * 1000)))
            mediumImpact()
        }

        // 特殊球 - 重冲击
        try? await Task.sleep(for: .milliseconds(Int(specialBallDelay * 1000)))
        heavyImpact()

        // 完成 - 成功反馈
        try? await Task.sleep(for: .milliseconds(200))
        success()
    }
}
