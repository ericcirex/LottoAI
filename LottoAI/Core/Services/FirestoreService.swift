import Foundation
// Firebase SDK (暂时禁用)
// import FirebaseFirestore
// import FirebaseAuth

/// 本地数据服务 (Firebase 暂时禁用，使用 UserDefaults)
@MainActor
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private init() {}

    // MARK: - User Operations

    /// 保存用户资料
    func saveUser(_ user: AppUser) async throws {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "user_\(user.id)")
        }
    }

    /// 获取用户资料
    func getUser(id: String) async throws -> AppUser? {
        guard let data = UserDefaults.standard.data(forKey: "user_\(id)"),
              let user = try? JSONDecoder().decode(AppUser.self, from: data) else {
            return nil
        }
        return user
    }

    /// 删除用户数据
    func deleteUser(id: String) async throws {
        UserDefaults.standard.removeObject(forKey: "user_\(id)")
        UserDefaults.standard.removeObject(forKey: "tickets_\(id)")
        UserDefaults.standard.removeObject(forKey: "predictions_\(id)")
    }

    // MARK: - Scanned Tickets Operations

    /// 保存扫描的彩票
    func saveScannedTicket(_ ticket: ScannedTicket, userId: String) async throws {
        var tickets = await getScannedTickets(userId: userId)
        tickets.insert(ticket, at: 0)
        if let data = try? JSONEncoder().encode(tickets) {
            UserDefaults.standard.set(data, forKey: "tickets_\(userId)")
        }
    }

    /// 获取用户扫描的彩票列表
    func getScannedTickets(userId: String) async -> [ScannedTicket] {
        guard let data = UserDefaults.standard.data(forKey: "tickets_\(userId)"),
              let tickets = try? JSONDecoder().decode([ScannedTicket].self, from: data) else {
            return []
        }
        return tickets
    }

    /// 删除扫描的彩票
    func deleteScannedTicket(_ ticketId: String, userId: String) async throws {
        var tickets = await getScannedTickets(userId: userId)
        tickets.removeAll { $0.id == ticketId }
        if let data = try? JSONEncoder().encode(tickets) {
            UserDefaults.standard.set(data, forKey: "tickets_\(userId)")
        }
    }

    // MARK: - User Statistics

    /// 更新用户统计
    func updateUserStats(userId: String, predictions: Int = 0, scans: Int = 0, winnings: Double = 0) async throws {
        guard var user = try await getUser(id: userId) else { return }
        user.stats.totalPredictions += predictions
        user.stats.ticketsScanned += scans
        user.stats.totalWinnings += winnings
        user.stats.lastActiveAt = Date()
        try await saveUser(user)
    }

    // MARK: - Predictions History

    /// 保存预测历史
    func savePrediction(userId: String, prediction: SavedPrediction) async throws {
        var predictions = await getPredictions(userId: userId)
        predictions.insert(prediction, at: 0)
        if let data = try? JSONEncoder().encode(predictions) {
            UserDefaults.standard.set(data, forKey: "predictions_\(userId)")
        }
    }

    /// 获取预测历史
    func getPredictions(userId: String) async -> [SavedPrediction] {
        guard let data = UserDefaults.standard.data(forKey: "predictions_\(userId)"),
              let predictions = try? JSONDecoder().decode([SavedPrediction].self, from: data) else {
            return []
        }
        return predictions
    }
}
