import Foundation

/// 开奖结果
struct DrawResult: Codable, Identifiable {
    let drawDate: String
    let numbers: [Int]
    let specialBall: Int
    let jackpot: String?
    let multiplier: Int?

    var id: String { drawDate }

    /// 格式化日期显示
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: drawDate) else { return drawDate }

        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    /// 短日期显示
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: drawDate) else { return drawDate }

        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

/// 最新结果 API 响应
struct LatestResultsResponse: Codable {
    let lottery: String
    let lastUpdated: String
    let currentJackpot: String?  // 当前奖金（来自官方 API）
    let nextDrawDate: String?    // 下次开奖日期
    let results: [DrawResult]

    enum CodingKeys: String, CodingKey {
        case lottery
        case lastUpdated = "last_updated"
        case currentJackpot = "current_jackpot"
        case nextDrawDate = "next_draw_date"
        case results
    }
}

/// 冷热号数据
struct HotColdNumber: Codable, Identifiable {
    let number: Int
    let count: Int
    let percentage: Double

    var id: Int { number }
}

/// 冷热号 API 响应
struct HotColdResponse: Codable {
    let lottery: String
    let analyzedDraws: Int
    let mainNumbers: MainNumberAnalysis
    let specialBall: SpecialBallAnalysis

    enum CodingKeys: String, CodingKey {
        case lottery
        case analyzedDraws = "analyzed_draws"
        case mainNumbers = "main_numbers"
        case specialBall = "special_ball"
    }

    struct MainNumberAnalysis: Codable {
        let hotNumbers: [HotColdNumber]
        let coldNumbers: [HotColdNumber]

        enum CodingKeys: String, CodingKey {
            case hotNumbers = "hot_numbers"
            case coldNumbers = "cold_numbers"
        }
    }

    struct SpecialBallAnalysis: Codable {
        let hotNumbers: [HotColdNumber]
        let coldNumbers: [HotColdNumber]

        enum CodingKeys: String, CodingKey {
            case hotNumbers = "hot_numbers"
            case coldNumbers = "cold_numbers"
        }
    }
}
