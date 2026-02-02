import StoreKit
import SwiftUI

/// 订阅管理器
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var subscriptionStatus: SubscriptionStatus = .none

    private let productIds = Constants.Products.all

    private init() {
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    // MARK: - 加载产品

    func loadProducts() async {
        do {
            products = try await Product.products(for: Set(productIds))
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - 购买

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - 恢复购买

    func restorePurchases() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
        }
        await updateSubscriptionStatus()
    }

    // MARK: - 更新订阅状态

    func updateSubscriptionStatus() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            subscriptionStatus = .active(expiresAt: expirationDate)
                            return
                        }
                    }
                }
            }
        }
        subscriptionStatus = .none
    }

    // MARK: - 验证交易

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - 订阅状态
enum SubscriptionStatus: Equatable {
    case none
    case trial(daysRemaining: Int)
    case active(expiresAt: Date)
    case expired

    var isPremium: Bool {
        switch self {
        case .trial, .active:
            return true
        case .none, .expired:
            return false
        }
    }

    var displayText: String {
        switch self {
        case .none:
            return "Free Plan"
        case .trial(let days):
            return "Trial (\(days) days left)"
        case .active(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Active until \(formatter.string(from: date))"
        case .expired:
            return "Expired"
        }
    }
}

// MARK: - 错误
enum SubscriptionError: LocalizedError {
    case failedVerification
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}
