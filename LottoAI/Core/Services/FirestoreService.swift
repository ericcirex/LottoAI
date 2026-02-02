import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Firestore 数据库服务
@MainActor
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User Operations

    /// 保存用户资料
    func saveUser(_ user: AppUser) async throws {
        try db.collection("users").document(user.id).setData(from: user, merge: true)

        // 本地缓存
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "user_\(user.id)")
        }
    }

    /// 获取用户资料
    func getUser(id: String) async throws -> AppUser? {
        let doc = try await db.collection("users").document(id).getDocument()
        return try? doc.data(as: AppUser.self)
    }

    /// 删除用户数据
    func deleteUser(id: String) async throws {
        try await db.collection("users").document(id).delete()
        try await deleteAllUserTickets(userId: id)

        // 清除本地缓存
        UserDefaults.standard.removeObject(forKey: "user_\(id)")
        UserDefaults.standard.removeObject(forKey: "tickets_\(id)")
    }

    // MARK: - Scanned Tickets Operations

    /// 保存扫描的彩票
    func saveScannedTicket(_ ticket: ScannedTicket, userId: String) async throws {
        try db.collection("scanned_tickets").document(ticket.id).setData(from: ticket)

        // 本地缓存
        var tickets = await getScannedTickets(userId: userId)
        tickets.insert(ticket, at: 0)
        if let data = try? JSONEncoder().encode(tickets) {
            UserDefaults.standard.set(data, forKey: "tickets_\(userId)")
        }
    }

    /// 获取用户扫描的彩票列表
    func getScannedTickets(userId: String) async -> [ScannedTicket] {
        do {
            let snapshot = try await db.collection("scanned_tickets")
                .whereField("userId", isEqualTo: userId)
                .order(by: "scannedAt", descending: true)
                .limit(to: 100)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: ScannedTicket.self) }
        } catch {
            // 从本地缓存读取
            guard let data = UserDefaults.standard.data(forKey: "tickets_\(userId)"),
                  let tickets = try? JSONDecoder().decode([ScannedTicket].self, from: data) else {
                return []
            }
            return tickets
        }
    }

    /// 删除扫描的彩票
    func deleteScannedTicket(_ ticketId: String, userId: String) async throws {
        try await db.collection("scanned_tickets").document(ticketId).delete()

        // 更新本地缓存
        var tickets = await getScannedTickets(userId: userId)
        tickets.removeAll { $0.id == ticketId }
        if let data = try? JSONEncoder().encode(tickets) {
            UserDefaults.standard.set(data, forKey: "tickets_\(userId)")
        }
    }

    /// 删除用户所有彩票记录
    private func deleteAllUserTickets(userId: String) async throws {
        let snapshot = try await db.collection("scanned_tickets")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()

        UserDefaults.standard.removeObject(forKey: "tickets_\(userId)")
    }

    // MARK: - User Statistics

    /// 更新用户统计
    func updateUserStats(userId: String, predictions: Int = 0, scans: Int = 0, winnings: Double = 0) async throws {
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "stats.total_predictions": FieldValue.increment(Int64(predictions)),
            "stats.tickets_scanned": FieldValue.increment(Int64(scans)),
            "stats.total_winnings": FieldValue.increment(winnings),
            "stats.last_active_at": Timestamp()
        ])
    }

    // MARK: - Predictions History

    /// 保存预测历史
    func savePrediction(userId: String, prediction: SavedPrediction) async throws {
        try db.collection("users").document(userId)
            .collection("predictions")
            .document(prediction.id.uuidString)
            .setData(from: prediction)
    }

    /// 获取预测历史
    func getPredictions(userId: String) async -> [SavedPrediction] {
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("predictions")
                .order(by: "savedAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: SavedPrediction.self) }
        } catch {
            // 从本地缓存读取
            guard let data = UserDefaults.standard.data(forKey: "predictions_\(userId)"),
                  let predictions = try? JSONDecoder().decode([SavedPrediction].self, from: data) else {
                return []
            }
            return predictions
        }
    }
}
