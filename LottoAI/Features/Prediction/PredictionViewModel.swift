import SwiftUI

@MainActor
class PredictionViewModel: ObservableObject {
    @Published var currentPrediction: Prediction?
    @Published var predictions: [Prediction] = []
    @Published var isGenerating = false
    @Published var todayQuote: Quote?
    @Published var errorMessage: String?

    let loadingMessages = [
        "Loading historical data...",
        "Checking frequency patterns...",
        "Reviewing hot & cold numbers...",
        "Applying selected strategy...",
        "Generating your numbers..."
    ]

    private let apiService = APIService.shared

    /// 生成号码
    func generatePrediction(for lottery: LotteryType) async {
        isGenerating = true
        currentPrediction = nil

        // 添加延迟增加仪式感 (3秒)
        try? await Task.sleep(for: .seconds(3))

        do {
            // 获取 API 预测
            let response = try await apiService.fetchPredictions(for: lottery)

            if let first = response.predictions.first {
                let strategy = PredictionStrategy(rawValue: first.strategy) ?? .random
                currentPrediction = Prediction(
                    numbers: first.numbers,
                    specialBall: first.specialBall,
                    strategy: strategy,
                    confidence: first.confidence
                )
            }

            // 获取今日金句
            let quotes = try await apiService.fetchQuotes()
            todayQuote = Quote.todayQuote(from: quotes)

        } catch {
            errorMessage = error.localizedDescription
            // 使用本地生成的随机预测
            currentPrediction = generateLocalPrediction(for: lottery)
        }

        if let prediction = currentPrediction {
            predictions.insert(prediction, at: 0)

            // 更新用户统计
            if let userId = AuthenticationManager.shared.currentUser?.id {
                try? await FirestoreService.shared.updateUserStats(userId: userId, predictions: 1)
            }
        }

        isGenerating = false
        HapticManager.success()
    }

    /// 本地生成随机预测 (离线备用)
    private func generateLocalPrediction(for lottery: LotteryType) -> Prediction {
        var mainNumbers: Set<Int> = []
        while mainNumbers.count < lottery.mainNumberCount {
            mainNumbers.insert(Int.random(in: lottery.mainNumberRange))
        }

        let specialBall = Int.random(in: lottery.specialNumberRange)

        return Prediction(
            numbers: Array(mainNumbers).sorted(),
            specialBall: specialBall,
            strategy: .random,
            confidence: Double.random(in: 0.7...0.95)
        )
    }

    /// 清除当前预测 (生成新的)
    func reset() {
        currentPrediction = nil
    }
}
