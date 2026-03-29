import Foundation
import StoreKit
import Observation

// MARK: - Error Types

enum SubscriptionError: LocalizedError {
    case userCancelled
    case pending
    case verificationFailed
    case productNotFound
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .verificationFailed:
            return "Transaction verification failed."
        case .productNotFound:
            return "Subscription product not found."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Subscription Info

struct SubscriptionInfo: Equatable {
    let productID: String
    let expirationDate: Date?
    let isInGracePeriod: Bool
    let willAutoRenew: Bool
}

// MARK: - Protocol

protocol SubscriptionServiceProtocol: AnyObject, Sendable {
    var isSubscribed: Bool { get async }
    var currentSubscription: SubscriptionInfo? { get async }
    func loadProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> StoreKit.Transaction
    func restorePurchases() async throws
}

// MARK: - Implementation

@Observable
@MainActor
final class SubscriptionService: SubscriptionServiceProtocol {
    static let shared = SubscriptionService()

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var subscriptionInfo: SubscriptionInfo?

    private let productIDs = ["qyra.monthly", "qyra.yearly"]
    private var transactionListenerTask: Task<Void, Error>?

    nonisolated init() {}

    func startListening() {
        guard transactionListenerTask == nil else { return }
        transactionListenerTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - Subscription Status

    var isSubscribed: Bool {
        get async {
            await updateSubscriptionStatus()
            return !purchasedProductIDs.isEmpty
        }
    }

    var currentSubscription: SubscriptionInfo? {
        get async {
            await updateSubscriptionStatus()
            return subscriptionInfo
        }
    }

    private func updateSubscriptionStatus() async {
        var activeIDs: Set<String> = []
        var latestInfo: SubscriptionInfo?

        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIDs.contains(transaction.productID) &&
                   transaction.revocationDate == nil {
                    activeIDs.insert(transaction.productID)

                    latestInfo = SubscriptionInfo(
                        productID: transaction.productID,
                        expirationDate: transaction.expirationDate,
                        isInGracePeriod: transaction.isUpgraded,
                        willAutoRenew: true
                    )
                }
            }
        }

        purchasedProductIDs = activeIDs
        subscriptionInfo = latestInfo
    }

    // MARK: - Products

    func loadProducts() async throws -> [Product] {
        let storeProducts = try await Product.products(for: productIDs)

        // Sort: yearly first (better value proposition shown first)
        products = storeProducts.sorted { lhs, rhs in
            let lhsIsYearly = lhs.subscription?.subscriptionPeriod.unit == .year
            let rhsIsYearly = rhs.subscription?.subscriptionPeriod.unit == .year
            return lhsIsYearly && !rhsIsYearly
        }

        return products
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> StoreKit.Transaction {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            purchasedProductIDs.insert(transaction.productID)
            await updateSubscriptionStatus()

            // Sync subscription event to Supabase
            syncSubscriptionEvent(
                event: "subscription_started",
                productId: transaction.productID,
                transactionId: String(transaction.id)
            )

            // Track in analytics
            AnalyticsService.shared.track(.subscriptionStarted, properties: [
                "product_id": transaction.productID,
                "transaction_id": String(transaction.id)
            ])

            return transaction

        case .userCancelled:
            throw SubscriptionError.userCancelled

        case .pending:
            throw SubscriptionError.pending

        @unknown default:
            throw SubscriptionError.unknown(
                NSError(domain: "Qyra", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown purchase result"])
            )
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()

        if purchasedProductIDs.isEmpty {
            throw SubscriptionError.productNotFound
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw SubscriptionError.verificationFailed
        }
    }

    // MARK: - Supabase Sync

    /// Fire-and-forget subscription event to Supabase for business analytics
    private func syncSubscriptionEvent(event: String, productId: String, transactionId: String) {
        guard let userId = CurrentUserProvider.shared.userId else { return }

        Task.detached {
            let baseURL = "https://oqjmxdxcwsajawesyspa.supabase.co"
            let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xam14ZHhjd3NhamF3ZXN5c3BhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2NTAyMTQsImV4cCI6MjA4ODIyNjIxNH0.m5tLk5asnA9Jb-lZ64Tg9RiKNbSk3gH6QE8qbBPBRG4"

            guard let url = URL(string: "\(baseURL)/rest/v1/macra_subscription_events") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(userId)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "user_id": userId,
                "event_type": event,
                "product_id": productId,
                "transaction_id": transactionId,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
