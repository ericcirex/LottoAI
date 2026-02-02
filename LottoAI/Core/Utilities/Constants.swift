import Foundation

/// 应用常量
enum Constants {
    /// API 基础 URL
    static let apiBaseURL = "https://ericcirex.github.io/lotto-ai-api"

    /// 订阅产品 ID
    enum Products {
        static let weekly = "com.lottoai.subscription.weekly"
        static let monthly = "com.lottoai.subscription.monthly"
        static let yearly = "com.lottoai.subscription.yearly"

        static let all = [weekly, monthly, yearly]
    }

    /// 缓存键
    enum CacheKeys {
        static let lastFetchDate = "lastFetchDate"
        static let cachedResults = "cachedResults"
        static let savedPredictions = "savedPredictions"
    }

    /// 通知名称
    enum Notifications {
        static let drawReminder = "drawReminder"
        static let resultAvailable = "resultAvailable"
        static let dailyFortune = "dailyFortune"
    }

    /// 动画时长
    enum Animation {
        static let ballRevealDelay: Double = 0.4
        static let loadingDuration: Double = 3.0
        static let cardTransition: Double = 0.3
    }

    /// 免费版限制
    enum FreeLimit {
        static let dailyPredictions = 1
        static let historyCount = 5
        static let strategies = 1
    }
}
