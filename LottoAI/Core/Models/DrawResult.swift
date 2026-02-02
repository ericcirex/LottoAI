import Foundation

/// 开奖结果
struct DrawResult: Codable, Identifiable {
    let drawDate: String
    let numbers: [Int]
    let specialBall: Int
    let jackpot: String?
    let multiplier: String?  // API 返回字符串类型

    var id: String { drawDate }

    enum CodingKeys: String, CodingKey {
        case drawDate = "draw_date"
        case numbers
        case specialBall = "special_ball"
        case jackpot
        case multiplier
    }

    /// 获取 multiplier 数值
    var multiplierValue: Int? {
        guard let m = multiplier else { return nil }
        return Int(m)
    }

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

/// 冷热号 API 响应 (匹配实际 API 格式)
struct HotColdResponse: Codable {
    let lottery: String
    let analysisPeriod: String
    let lastUpdated: String
    let hotNumbers: NumberSet
    let coldNumbers: NumberSet
    let frequency: FrequencyData

    enum CodingKeys: String, CodingKey {
        case lottery
        case analysisPeriod = "analysis_period"
        case lastUpdated = "last_updated"
        case hotNumbers = "hot_numbers"
        case coldNumbers = "cold_numbers"
        case frequency
    }

    struct NumberSet: Codable {
        let main: [Int]
        let special: [Int]
    }

    struct FrequencyData: Codable {
        let main: [String: Int]
        let special: [String: Int]
    }
}
