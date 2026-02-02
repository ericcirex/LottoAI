import SwiftUI
import Vision
import UIKit

/// 扫描状态
enum ScanState: Equatable {
    case idle
    case scanning
    case confirming(numbers: [Int], specialBall: Int)
    case checking
    case result(ScannedTicket)
    case error(String)

    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.scanning, .scanning), (.checking, .checking):
            return true
        case (.confirming(let n1, let s1), .confirming(let n2, let s2)):
            return n1 == n2 && s1 == s2
        case (.result(let t1), .result(let t2)):
            return t1.id == t2.id
        case (.error(let e1), .error(let e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

/// 彩票扫描 ViewModel
@MainActor
class TicketScannerViewModel: ObservableObject {
    @Published var scanState: ScanState = .idle
    @Published var selectedLottery: LotteryType = .powerball

    // MARK: - Scan Image
    func scanImage(_ image: UIImage) {
        scanState = .scanning

        Task {
            do {
                let numbers = try await recognizeNumbers(from: image)

                if numbers.count >= 6 {
                    // 分离主号码和特殊号码
                    let mainNumbers = Array(numbers.prefix(5)).sorted()
                    let specialBall = numbers[5]

                    scanState = .confirming(numbers: mainNumbers, specialBall: specialBall)
                    HapticManager.success()
                } else {
                    scanState = .error("Could not detect enough numbers. Please try again with a clearer image.")
                    HapticManager.error()
                }
            } catch {
                scanState = .error(error.localizedDescription)
                HapticManager.error()
            }
        }
    }

    // MARK: - Confirm Numbers
    func confirmNumbers(_ numbers: [Int], special: Int) {
        scanState = .checking
        HapticManager.mediumImpact()

        Task {
            // 模拟检查延迟
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // 获取最新开奖结果并对比
            let result = await checkAgainstLatestDraw(numbers: numbers, specialBall: special)

            let ticket = ScannedTicket(
                id: UUID().uuidString,
                userId: AuthenticationManager.shared.currentUser?.id ?? "guest",
                lotteryType: selectedLottery.rawValue,
                numbers: numbers,
                specialBall: special,
                drawDate: result.drawDate,
                scannedAt: Date(),
                isChecked: true,
                isWinner: result.isWinner,
                prizeAmount: result.prizeAmount,
                prizeTier: result.prizeTier?.rawValue
            )

            // 保存到数据库和用户统计
            if let userId = AuthenticationManager.shared.currentUser?.id {
                try? await FirestoreService.shared.saveScannedTicket(ticket, userId: userId)
                try? await FirestoreService.shared.updateUserStats(
                    userId: userId,
                    scans: 1,
                    winnings: result.isWinner ? result.prizeAmount : 0
                )
            }

            scanState = .result(ticket)

            if result.isWinner {
                HapticManager.heavyImpact()
            }
        }
    }

    // MARK: - Reset
    func reset() {
        scanState = .idle
    }

    // MARK: - OCR Recognition
    private func recognizeNumbers(from image: UIImage) async throws -> [Int] {
        guard let cgImage = image.cgImage else {
            throw ScanError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                // 提取所有识别到的数字
                var numbers: [Int] = []

                for observation in observations {
                    guard let text = observation.topCandidates(1).first?.string else { continue }

                    // 使用正则提取数字
                    let pattern = "\\b([1-9]|[1-6][0-9]|70)\\b"
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let range = NSRange(text.startIndex..<text.endIndex, in: text)
                        let matches = regex.matches(in: text, range: range)

                        for match in matches {
                            if let swiftRange = Range(match.range, in: text),
                               let number = Int(text[swiftRange]) {
                                // 过滤彩票有效范围内的数字
                                if number >= 1 && number <= 70 {
                                    numbers.append(number)
                                }
                            }
                        }
                    }
                }

                // 去重并保持顺序
                var seen = Set<Int>()
                let uniqueNumbers = numbers.filter { seen.insert($0).inserted }

                continuation.resume(returning: uniqueNumbers)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Check Against Latest Draw
    private func checkAgainstLatestDraw(numbers: [Int], specialBall: Int) async -> DrawCheckResult {
        // 模拟获取最新开奖结果
        // 实际实现中应该调用 API 获取真实数据
        let mockWinningNumbers = [7, 14, 21, 35, 62]
        let mockWinningSpecial = 19

        // 计算匹配
        let matchedMain = numbers.filter { mockWinningNumbers.contains($0) }.count
        let matchedSpecial = specialBall == mockWinningSpecial

        let prizeTier = determinePrizeTier(mainMatches: matchedMain, specialMatch: matchedSpecial)

        return DrawCheckResult(
            drawDate: "2026-02-01",
            winningNumbers: mockWinningNumbers,
            winningSpecial: mockWinningSpecial,
            isWinner: prizeTier != .none,
            prizeTier: prizeTier,
            prizeAmount: prizeAmountFor(tier: prizeTier)
        )
    }

    private func determinePrizeTier(mainMatches: Int, specialMatch: Bool) -> PrizeTier {
        switch (mainMatches, specialMatch) {
        case (5, true): return .jackpot
        case (5, false): return .second
        case (4, true): return .third
        case (4, false): return .fourth
        case (3, true): return .fifth
        case (3, false): return .sixth
        case (2, true): return .seventh
        case (1, true): return .eighth
        case (0, true): return .ninth
        default: return .none
        }
    }

    private func prizeAmountFor(tier: PrizeTier) -> Double {
        switch tier {
        case .jackpot: return 100_000_000
        case .second: return 1_000_000
        case .third: return 50_000
        case .fourth: return 100
        case .fifth: return 100
        case .sixth: return 7
        case .seventh: return 7
        case .eighth: return 4
        case .ninth: return 4
        case .none: return 0
        }
    }
}

// MARK: - Supporting Types
struct DrawCheckResult {
    let drawDate: String
    let winningNumbers: [Int]
    let winningSpecial: Int
    let isWinner: Bool
    let prizeTier: PrizeTier?
    let prizeAmount: Double
}

enum ScanError: LocalizedError {
    case invalidImage
    case noNumbersFound
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process image"
        case .noNumbersFound: return "No numbers found in image"
        case .recognitionFailed: return "Text recognition failed"
        }
    }
}
