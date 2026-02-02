import Foundation

/// API 服务 - 支持 GitHub Actions (静态 JSON) 后端
actor APIService {
    static let shared = APIService()

    /// API 后端类型
    enum Backend {
        case githubActions  // GitHub Actions + GitHub Pages (推荐，免费)
        case githubPages    // 旧版 GitHub Pages 地址
        case local          // 本地开发

        var baseURL: String {
            switch self {
            case .githubActions:
                // TODO: 部署后替换为你的 GitHub Pages 域名
                // 格式: https://<username>.github.io/<repo-name>
                return "https://ericcirex.github.io/LottoAI"
            case .githubPages:
                return "https://ericcirex.github.io/lotto-ai-api"
            case .local:
                return "http://localhost:8000"
            }
        }

        var fileExtension: String {
            return ".json"  // 所有静态后端都使用 .json
        }
    }

    // 切换后端类型 - 使用 GitHub Actions 自动更新
    private let backend: Backend = .githubActions

    private var baseURL: String { backend.baseURL }
    private var ext: String { backend.fileExtension }
    private let decoder: JSONDecoder

    private init() {
        decoder = JSONDecoder()
    }

    // MARK: - Public API

    /// 获取最新开奖结果
    func fetchLatestResults(for lottery: LotteryType) async throws -> LatestResultsResponse {
        let url = "\(baseURL)/\(lottery.apiPath)/latest_results\(ext)"
        return try await fetch(url)
    }

    /// 获取冷热号分析
    func fetchHotColdNumbers(for lottery: LotteryType) async throws -> HotColdResponse {
        let url = "\(baseURL)/\(lottery.apiPath)/hot_cold_numbers\(ext)"
        return try await fetch(url)
    }

    /// 获取 AI 预测
    func fetchPredictions(for lottery: LotteryType) async throws -> PredictionsResponse {
        let url = "\(baseURL)/\(lottery.apiPath)/ai_predictions\(ext)"
        return try await fetch(url)
    }

    /// 获取每日运势
    func fetchDailyFortune(for lottery: LotteryType) async throws -> DailyFortune {
        let url = "\(baseURL)/\(lottery.apiPath)/daily_fortune\(ext)"
        return try await fetch(url)
    }

    /// 获取每日金句库
    func fetchQuotes() async throws -> [Quote] {
        let url = "\(baseURL)/daily_quotes\(ext)"
        return try await fetch(url)
    }

    /// 获取 API 清单
    func fetchManifest() async throws -> APIManifest {
        let url = "\(baseURL)/manifest\(ext)"
        return try await fetch(url)
    }

    // MARK: - Private

    private func fetch<T: Decodable>(_ urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - API Manifest
struct APIManifest: Codable {
    let version: String
    let lastUpdated: String
    let lotteries: [String]
    let endpoints: [String: String]

    enum CodingKeys: String, CodingKey {
        case version
        case lastUpdated = "last_updated"
        case lotteries
        case endpoints
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        }
    }
}
