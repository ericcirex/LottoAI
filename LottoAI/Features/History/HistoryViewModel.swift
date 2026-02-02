import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var results: [DrawResult] = []
    @Published var hotColdData: HotColdResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared
    private var currentLottery: LotteryType = .powerball

    func loadData(for lottery: LotteryType) async {
        isLoading = true
        errorMessage = nil
        currentLottery = lottery

        do {
            async let resultsTask = apiService.fetchLatestResults(for: lottery)
            async let hotColdTask = apiService.fetchHotColdNumbers(for: lottery)

            let (resultsResponse, hotColdResponse) = try await (resultsTask, hotColdTask)

            results = resultsResponse.results
            hotColdData = hotColdResponse

        } catch {
            errorMessage = error.localizedDescription
            // 使用模拟数据 (根据彩票类型生成不同数据)
            results = generateMockResults(for: lottery)
            hotColdData = generateMockHotCold(for: lottery)
        }

        isLoading = false
    }

    // MARK: - Mock Data (彩票类型区分)

    private func generateMockResults(for lottery: LotteryType) -> [DrawResult] {
        let mainRange = lottery.mainNumberRange
        let specialRange = lottery.specialNumberRange

        // 使用固定种子确保每个彩票类型有不同但稳定的数据
        let baseSeed = lottery == .powerball ? 42 : 88

        return (0..<10).map { i in
            // 生成基于彩票类型的不同号码
            var numbers: [Int] = []
            for j in 0..<5 {
                let seed = (baseSeed + i * 7 + j * 13) % mainRange.count + mainRange.lowerBound
                numbers.append(min(seed, mainRange.upperBound))
            }
            numbers = Array(Set(numbers)).sorted()
            while numbers.count < 5 {
                numbers.append(Int.random(in: mainRange))
                numbers = Array(Set(numbers)).sorted()
            }

            let special = (baseSeed + i * 11) % specialRange.count + specialRange.lowerBound

            let jackpots = lottery == .powerball
                ? ["$1.9 Billion", "$800 Million", "$650 Million", "$500 Million", "$420 Million", "$380 Million", "$320 Million", "$280 Million", "$240 Million", "$200 Million"]
                : ["$1.2 Billion", "$720 Million", "$580 Million", "$450 Million", "$390 Million", "$340 Million", "$290 Million", "$250 Million", "$210 Million", "$180 Million"]

            return DrawResult(
                drawDate: "2026-01-\(String(format: "%02d", 29 - i))",
                numbers: Array(numbers.prefix(5)),
                specialBall: min(special, specialRange.upperBound),
                jackpot: jackpots[i],
                multiplier: ["2", "3", "4", "5", "10"][i % 5]
            )
        }
    }

    private func generateMockHotCold(for lottery: LotteryType) -> HotColdResponse {
        // Mock 数据 - 实际会从 API 获取
        if lottery == .powerball {
            return HotColdResponse(
                lottery: "Powerball",
                analysisPeriod: "Last 50 draws",
                lastUpdated: "2026-02-02",
                hotNumbers: HotColdResponse.NumberSet(
                    main: [28, 51, 5, 18, 8, 53, 32, 40, 63, 21],
                    special: [23, 14, 1, 12, 2]
                ),
                coldNumbers: HotColdResponse.NumberSet(
                    main: [42],
                    special: [6, 8, 9, 13, 24]
                ),
                frequency: HotColdResponse.FrequencyData(
                    main: ["28": 10, "51": 8, "5": 7],
                    special: ["23": 7, "14": 5, "1": 4]
                )
            )
        } else {
            return HotColdResponse(
                lottery: "Mega Millions",
                analysisPeriod: "Last 50 draws",
                lastUpdated: "2026-02-02",
                hotNumbers: HotColdResponse.NumberSet(
                    main: [31, 17, 46, 10, 70, 14, 1, 64, 62, 4],
                    special: [4, 13, 24, 22, 5]
                ),
                coldNumbers: HotColdResponse.NumberSet(
                    main: [21, 57, 19],
                    special: [2, 20, 7, 23, 25]
                ),
                frequency: HotColdResponse.FrequencyData(
                    main: ["31": 10, "17": 8, "46": 7],
                    special: ["4": 6, "13": 5, "24": 4]
                )
            )
        }
    }
}
