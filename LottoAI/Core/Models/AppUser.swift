import Foundation

/// 用户模型 - 存储在 Firestore
struct AppUser: Codable, Identifiable {
    let id: String                      // Apple User ID / Firebase UID
    var email: String?                  // 可选，用户可能不分享
    var displayName: String             // 显示名称
    var avatarURL: String?              // 头像 URL
    let createdAt: Date                 // 注册时间
    var isPremium: Bool = false         // 订阅状态
    var premiumExpiresAt: Date?         // 订阅过期时间
    var stats: UserStats                // 使用统计
    var preferences: UserPreferences?   // 用户偏好

    // MARK: - Firestore 字段映射
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case isPremium = "is_premium"
        case premiumExpiresAt = "premium_expires_at"
        case stats
        case preferences
    }
}

/// 用户统计数据
struct UserStats: Codable {
    var totalPredictions: Int = 0       // 总共生成的预测数
    var ticketsScanned: Int = 0         // 扫描的彩票数
    var ticketsWon: Int = 0             // 中奖彩票数
    var totalWinnings: Double = 0       // 总中奖金额
    var favoriteNumbers: [Int] = []     // 常用号码
    var lastActiveAt: Date?             // 最后活跃时间
    var consecutiveDays: Int = 0        // 连续使用天数
    var longestStreak: Int = 0          // 最长连续使用天数

    enum CodingKeys: String, CodingKey {
        case totalPredictions = "total_predictions"
        case ticketsScanned = "tickets_scanned"
        case ticketsWon = "tickets_won"
        case totalWinnings = "total_winnings"
        case favoriteNumbers = "favorite_numbers"
        case lastActiveAt = "last_active_at"
        case consecutiveDays = "consecutive_days"
        case longestStreak = "longest_streak"
    }
}

/// 用户偏好设置
struct UserPreferences: Codable {
    var preferredLottery: String = "powerball"  // 偏好的彩票类型
    var notificationsEnabled: Bool = true       // 是否开启通知
    var drawReminders: Bool = true              // 开奖提醒
    var resultNotifications: Bool = true        // 开奖结果通知

    enum CodingKeys: String, CodingKey {
        case preferredLottery = "preferred_lottery"
        case notificationsEnabled = "notifications_enabled"
        case drawReminders = "draw_reminders"
        case resultNotifications = "result_notifications"
    }
}

/// 扫描的彩票记录
struct ScannedTicket: Codable, Identifiable {
    let id: String                      // 唯一ID
    let userId: String                  // 用户ID
    let lotteryType: String             // powerball / mega_millions
    let numbers: [Int]                  // 主号码
    let specialBall: Int                // 特殊号码
    let drawDate: String?               // 开奖日期 (如果有)
    let scannedAt: Date                 // 扫描时间
    var isChecked: Bool = false         // 是否已对比
    var isWinner: Bool = false          // 是否中奖
    var prizeAmount: Double?            // 中奖金额
    var prizeTier: String?              // 中奖等级

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case lotteryType = "lottery_type"
        case numbers
        case specialBall = "special_ball"
        case drawDate = "draw_date"
        case scannedAt = "scanned_at"
        case isChecked = "is_checked"
        case isWinner = "is_winner"
        case prizeAmount = "prize_amount"
        case prizeTier = "prize_tier"
    }
}

// MARK: - Prize Tiers
enum PrizeTier: String, CaseIterable {
    case jackpot = "Jackpot"
    case second = "Match 5"
    case third = "Match 4 + Ball"
    case fourth = "Match 4"
    case fifth = "Match 3 + Ball"
    case sixth = "Match 3"
    case seventh = "Match 2 + Ball"
    case eighth = "Match 1 + Ball"
    case ninth = "Match Ball Only"
    case none = "No Prize"

    var displayName: String { rawValue }

    var celebrationMessage: String {
        switch self {
        case .jackpot:
            return "🎉 JACKPOT WINNER! 🎉\nCongratulations! You've hit the ultimate prize!"
        case .second:
            return "🌟 Amazing! You matched 5 numbers!\nA fantastic win - you're so close to the jackpot!"
        case .third:
            return "✨ Wonderful! You matched 4 + the special ball!\nThat's a great prize!"
        case .fourth:
            return "🎯 Nice! You matched 4 numbers!\nKeep that lucky streak going!"
        case .fifth:
            return "💫 Great! 3 numbers + the special ball!\nYou're definitely on a roll!"
        case .sixth:
            return "👍 Good job! You matched 3 numbers!\nEvery win counts!"
        case .seventh:
            return "🍀 Lucky! 2 numbers + the special ball!\nThe universe is smiling on you!"
        case .eighth:
            return "✨ You matched 1 number + the special ball!\nA small win is still a win!"
        case .ninth:
            return "🎱 You matched the special ball!\nBetter luck is coming your way!"
        case .none:
            return "💪 No win this time, but don't give up!\nYour lucky numbers are waiting for you!"
        }
    }
}
