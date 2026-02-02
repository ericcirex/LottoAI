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
                multiplier: [2, 3, 4, 5, 10][i % 5]
            )
        }
    }

    private func generateMockHotCold(for lottery: LotteryType) -> HotColdResponse {
        // Powerball 和 Mega Millions 有完全不同的热冷号数据
        let hotNumbers: [HotColdNumber]
        let coldNumbers: [HotColdNumber]
        let hotSpecial: [HotColdNumber]
        let coldSpecial: [HotColdNumber]

        if lottery == .powerball {
            // Powerball 热号: 基于实际统计的常见号码
            hotNumbers = [
                HotColdNumber(number: 21, count: 32, percentage: 0.16),
                HotColdNumber(number: 36, count: 30, percentage: 0.15),
                HotColdNumber(number: 23, count: 29, percentage: 0.145),
                HotColdNumber(number: 61, count: 28, percentage: 0.14),
                HotColdNumber(number: 69, count: 27, percentage: 0.135),
                HotColdNumber(number: 39, count: 26, percentage: 0.13),
                HotColdNumber(number: 59, count: 25, percentage: 0.125),
                HotColdNumber(number: 32, count: 24, percentage: 0.12),
                HotColdNumber(number: 10, count: 23, percentage: 0.115),
                HotColdNumber(number: 62, count: 22, percentage: 0.11)
            ]
            coldNumbers = [
                HotColdNumber(number: 26, count: 8, percentage: 0.04),
                HotColdNumber(number: 34, count: 9, percentage: 0.045),
                HotColdNumber(number: 48, count: 10, percentage: 0.05),
                HotColdNumber(number: 51, count: 11, percentage: 0.055),
                HotColdNumber(number: 65, count: 12, percentage: 0.06),
                HotColdNumber(number: 13, count: 13, percentage: 0.065),
                HotColdNumber(number: 44, count: 14, percentage: 0.07),
                HotColdNumber(number: 55, count: 14, percentage: 0.07),
                HotColdNumber(number: 67, count: 15, percentage: 0.075),
                HotColdNumber(number: 29, count: 15, percentage: 0.075)
            ]
            hotSpecial = [
                HotColdNumber(number: 24, count: 28, percentage: 0.14),
                HotColdNumber(number: 18, count: 26, percentage: 0.13),
                HotColdNumber(number: 21, count: 24, percentage: 0.12),
                HotColdNumber(number: 10, count: 22, percentage: 0.11),
                HotColdNumber(number: 4, count: 20, percentage: 0.10)
            ]
            coldSpecial = [
                HotColdNumber(number: 15, count: 6, percentage: 0.03),
                HotColdNumber(number: 23, count: 7, percentage: 0.035),
                HotColdNumber(number: 26, count: 8, percentage: 0.04),
                HotColdNumber(number: 8, count: 9, percentage: 0.045),
                HotColdNumber(number: 12, count: 10, percentage: 0.05)
            ]
        } else {
            // Mega Millions 热号: 不同的数据集
            hotNumbers = [
                HotColdNumber(number: 17, count: 35, percentage: 0.175),
                HotColdNumber(number: 31, count: 33, percentage: 0.165),
                HotColdNumber(number: 10, count: 31, percentage: 0.155),
                HotColdNumber(number: 46, count: 30, percentage: 0.15),
                HotColdNumber(number: 70, count: 29, percentage: 0.145),
                HotColdNumber(number: 14, count: 28, percentage: 0.14),
                HotColdNumber(number: 62, count: 27, percentage: 0.135),
                HotColdNumber(number: 28, count: 26, percentage: 0.13),
                HotColdNumber(number: 38, count: 25, percentage: 0.125),
                HotColdNumber(number: 53, count: 24, percentage: 0.12)
            ]
            coldNumbers = [
                HotColdNumber(number: 21, count: 7, percentage: 0.035),
                HotColdNumber(number: 45, count: 8, percentage: 0.04),
                HotColdNumber(number: 57, count: 9, percentage: 0.045),
                HotColdNumber(number: 66, count: 10, percentage: 0.05),
                HotColdNumber(number: 33, count: 11, percentage: 0.055),
                HotColdNumber(number: 49, count: 12, percentage: 0.06),
                HotColdNumber(number: 8, count: 13, percentage: 0.065),
                HotColdNumber(number: 25, count: 13, percentage: 0.065),
                HotColdNumber(number: 59, count: 14, percentage: 0.07),
                HotColdNumber(number: 68, count: 14, percentage: 0.07)
            ]
            hotSpecial = [
                HotColdNumber(number: 22, count: 30, percentage: 0.15),
                HotColdNumber(number: 11, count: 28, percentage: 0.14),
                HotColdNumber(number: 9, count: 26, percentage: 0.13),
                HotColdNumber(number: 3, count: 24, percentage: 0.12),
                HotColdNumber(number: 15, count: 22, percentage: 0.11)
            ]
            coldSpecial = [
                HotColdNumber(number: 19, count: 5, percentage: 0.025),
                HotColdNumber(number: 6, count: 6, percentage: 0.03),
                HotColdNumber(number: 24, count: 7, percentage: 0.035),
                HotColdNumber(number: 1, count: 8, percentage: 0.04),
                HotColdNumber(number: 13, count: 9, percentage: 0.045)
            ]
        }

        return HotColdResponse(
            lottery: lottery.rawValue,
            analyzedDraws: 200,
            mainNumbers: HotColdResponse.MainNumberAnalysis(
                hotNumbers: hotNumbers,
                coldNumbers: coldNumbers
            ),
            specialBall: HotColdResponse.SpecialBallAnalysis(
                hotNumbers: hotSpecial,
                coldNumbers: coldSpecial
            )
        )
    }
}
