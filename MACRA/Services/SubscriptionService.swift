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
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var subscriptionInfo: SubscriptionInfo?

    private let productIDs = ["macra.monthly", "macra.yearly"]
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
            return transaction

        case .userCancelled:
            throw SubscriptionError.userCancelled

        case .pending:
            throw SubscriptionError.pending

        @unknown default:
            throw SubscriptionError.unknown(
                NSError(domain: "MACRA", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown purchase result"])
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
}
