import Foundation

/// 生成的号码组合
struct Prediction: Codable, Identifiable {
    let id: UUID
    let numbers: [Int]
    let specialBall: Int
    let strategy: PredictionStrategy
    let confidence: Double
    let createdAt: Date

    init(
        numbers: [Int],
        specialBall: Int,
        strategy: PredictionStrategy,
        confidence: Double
    ) {
        self.id = UUID()
        self.numbers = numbers
        self.specialBall = specialBall
        self.strategy = strategy
        self.confidence = confidence
        self.createdAt = Date()
    }

    /// 统计匹配度显示
    var confidenceDisplay: String {
        String(format: "%.0f%% match", confidence * 100)
    }

    /// 策略名称
    var strategyName: String {
        strategy.displayName
    }
}

/// 预测策略
enum PredictionStrategy: String, Codable, CaseIterable {
    case hotFocus = "hot_focus"
    case coldFocus = "cold_focus"
    case balanced = "balanced"
    case frequency = "frequency"
    case random = "random"

    var displayName: String {
        switch self {
        case .hotFocus: return "Hot Numbers"
        case .coldFocus: return "Cold Numbers"
        case .balanced: return "Balanced Mix"
        case .frequency: return "Frequency Based"
        case .random: return "Lucky Random"
        }
    }

    var description: String {
        switch self {
        case .hotFocus: return "Focus on recently frequent numbers"
        case .coldFocus: return "Focus on overdue numbers"
        case .balanced: return "Mix of hot and cold numbers"
        case .frequency: return "Based on historical frequency"
        case .random: return "Purely random selection"
        }
    }

    var iconName: String {
        switch self {
        case .hotFocus: return "flame.fill"
        case .coldFocus: return "snowflake"
        case .balanced: return "scale.3d"
        case .frequency: return "chart.bar.fill"
        case .random: return "dice.fill"
        }
    }
}

/// API 预测响应
struct PredictionsResponse: Codable {
    let lottery: String
    let generatedAt: String
    let predictions: [APIPrediction]

    enum CodingKeys: String, CodingKey {
        case lottery
        case generatedAt = "generated_at"
        case predictions
    }

    struct APIPrediction: Codable {
        let strategy: String
        let numbers: [Int]
        let specialBall: Int
        let confidence: Double

        enum CodingKeys: String, CodingKey {
            case strategy
            case numbers
            case specialBall = "special_ball"
            case confidence
        }
    }
}
