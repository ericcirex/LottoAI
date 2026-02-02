import SwiftUI

/// 彩票类型
enum LotteryType: String, CaseIterable, Identifiable, Codable {
    case powerball = "powerball"
    case megaMillions = "mega_millions"

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .powerball: return "Powerball"
        case .megaMillions: return "Mega Millions"
        }
    }

    /// 简短名称
    var shortName: String {
        switch self {
        case .powerball: return "PB"
        case .megaMillions: return "MM"
        }
    }

    /// Logo 图标
    var iconName: String {
        switch self {
        case .powerball: return "circle.fill"
        case .megaMillions: return "star.circle.fill"
        }
    }

    /// 主题色 (Powerball=红色, Mega Millions=金色)
    var themeColor: Color {
        switch self {
        case .powerball: return AppColors.luckyRed       // 红色
        case .megaMillions: return AppColors.gold        // 金色
        }
    }

    /// 主号码范围
    var mainNumberRange: ClosedRange<Int> {
        switch self {
        case .powerball: return 1...69
        case .megaMillions: return 1...70
        }
    }

    /// 特殊号码范围
    var specialNumberRange: ClosedRange<Int> {
        switch self {
        case .powerball: return 1...26
        case .megaMillions: return 1...25
        }
    }

    /// 主号码数量
    var mainNumberCount: Int { 5 }

    /// API 路径
    var apiPath: String { rawValue }

    /// 开奖时间说明
    var drawSchedule: String {
        switch self {
        case .powerball: return "Mon, Wed, Sat at 10:59 PM ET"
        case .megaMillions: return "Tue, Fri at 11:00 PM ET"
        }
    }

    /// 开奖日期 (Weekday)
    var drawDays: [Int] {
        switch self {
        case .powerball: return [2, 4, 7]      // Mon, Wed, Sat
        case .megaMillions: return [3, 6]      // Tue, Fri
        }
    }
}
