import Foundation

/// 每日金句
struct Quote: Codable, Identifiable {
    var id: Int
    let text: String
    let author: String?
    var category: QuoteCategory

    enum CodingKeys: String, CodingKey {
        case text
        case author
    }

    init(id: Int, text: String, author: String?, category: QuoteCategory) {
        self.id = id
        self.text = text
        self.author = author
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        // 自动生成 id 和 category
        self.id = text.hashValue
        self.category = .luck
    }

    /// 今日金句 (基于日期选择，每天自动更换)
    static func todayQuote(from quotes: [Quote]) -> Quote? {
        guard !quotes.isEmpty else { return nil }

        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % quotes.count

        return quotes[index]
    }
}

/// 金句类别
enum QuoteCategory: String, Codable {
    case luck
    case fortune
    case motivation
    case wisdom
    case positivity

    var displayName: String {
        switch self {
        case .luck: return "Luck"
        case .fortune: return "Fortune"
        case .motivation: return "Motivation"
        case .wisdom: return "Wisdom"
        case .positivity: return "Positivity"
        }
    }

    var emoji: String {
        switch self {
        case .luck: return "🍀"
        case .fortune: return "💰"
        case .motivation: return "🚀"
        case .wisdom: return "🦉"
        case .positivity: return "✨"
        }
    }
}

/// 每日运势
struct DailyFortune: Codable {
    let date: String
    let fortuneLevel: Int
    let luckyNumbers: [Int]
    let luckyColor: String
    let message: String
    let advice: String

    enum CodingKeys: String, CodingKey {
        case date
        case fortuneLevel = "fortune_level"
        case luckyNumbers = "lucky_numbers"
        case luckyColor = "lucky_color"
        case message
        case advice
    }

    /// 运势星级显示
    var starsDisplay: String {
        String(repeating: "★", count: fortuneLevel) +
        String(repeating: "☆", count: 5 - fortuneLevel)
    }
}
