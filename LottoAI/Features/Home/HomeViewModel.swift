import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var latestResult: DrawResult?
    @Published var jackpotAmount: String = "$---"
    @Published var todayQuote: Quote?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared
    private var quotesLoaded = false

    func loadData(for lottery: LotteryType) async {
        isLoading = true
        errorMessage = nil

        // 并行加载数据
        async let resultsTask = loadResults(for: lottery)
        async let quotesTask = loadQuotesIfNeeded()

        await resultsTask
        await quotesTask

        isLoading = false
    }

    private func loadResults(for lottery: LotteryType) async {
        do {
            let response = try await apiService.fetchLatestResults(for: lottery)

            if let firstResult = response.results.first {
                latestResult = firstResult
                // 优先使用 API 返回的 current_jackpot（来自官方数据）
                jackpotAmount = response.currentJackpot ?? firstResult.jackpot ?? formatDefaultJackpot(for: lottery)
            }
        } catch {
            errorMessage = error.localizedDescription
            // 使用模拟数据
            latestResult = mockResult(for: lottery)
            jackpotAmount = formatDefaultJackpot(for: lottery)
        }
    }

    private func loadQuotesIfNeeded() async {
        guard !quotesLoaded else { return }

        do {
            let quotes = try await apiService.fetchQuotes()
            todayQuote = Quote.todayQuote(from: quotes)
            quotesLoaded = true
        } catch {
            // 使用默认金句
            todayQuote = Quote(
                id: 1,
                text: "Fortune favors the bold.",
                author: "Virgil",
                category: .luck
            )
        }
    }

    private func formatDefaultJackpot(for lottery: LotteryType) -> String {
        switch lottery {
        case .powerball:
            return "$1.9 Billion"
        case .megaMillions:
            return "$850 Million"
        }
    }

    private func mockResult(for lottery: LotteryType) -> DrawResult {
        DrawResult(
            drawDate: "2026-01-29",
            numbers: lottery == .powerball
                ? [12, 24, 37, 45, 68]
                : [5, 18, 33, 42, 61],
            specialBall: lottery == .powerball ? 11 : 22,
            jackpot: formatDefaultJackpot(for: lottery),
            multiplier: "2"
        )
    }
}
