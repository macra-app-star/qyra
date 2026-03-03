import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class SubscriptionViewModel {
    private let subscriptionService: SubscriptionService

    var products: [Product] = []
    var selectedProduct: Product?
    var isPurchasing = false
    var isRestoring = false
    var isLoading = true
    var errorMessage: String?
    var showError = false

    init(subscriptionService: SubscriptionService = SubscriptionService()) {
        self.subscriptionService = subscriptionService
    }

    // MARK: - Computed Properties

    var purchaseButtonTitle: String {
        guard let product = selectedProduct else { return "Select a Plan" }

        if let intro = product.subscription?.introductoryOffer,
           intro.paymentMode == .freeTrial {
            let periodText = trialPeriodText(intro.period)
            return "Start \(periodText) Free Trial"
        }

        return "Subscribe for \(product.displayPrice)"
    }

    var savingsText: String? {
        guard products.count >= 2 else { return nil }

        let monthly = products.first { $0.subscription?.subscriptionPeriod.unit == .month }
        let yearly = products.first { $0.subscription?.subscriptionPeriod.unit == .year }

        guard let monthlyPrice = monthly?.price,
              let yearlyPrice = yearly?.price else { return nil }

        let yearlyMonthly = yearlyPrice / 12
        let savings = ((monthlyPrice - yearlyMonthly) / monthlyPrice) * 100
        let rounded = NSDecimalNumber(decimal: savings).intValue

        guard rounded > 0 else { return nil }
        return "Save \(rounded)%"
    }

    var canPurchase: Bool {
        selectedProduct != nil && !isPurchasing && !isRestoring
    }

    // MARK: - Actions

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await subscriptionService.loadProducts()

            // Pre-select yearly (better value)
            selectedProduct = products.first {
                $0.subscription?.subscriptionPeriod.unit == .year
            } ?? products.first
        } catch {
            errorMessage = "Unable to load subscription options. Please try again."
            showError = true
        }
    }

    func purchase() async {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            _ = try await subscriptionService.purchase(product)
            DesignTokens.Haptics.success()
            // AppState will detect entitlement change and navigate away
        } catch SubscriptionError.userCancelled {
            // Silent — user tapped cancel, no error shown
        } catch SubscriptionError.pending {
            errorMessage = "Your purchase is pending approval. You'll get access once it's approved."
            showError = true
        } catch {
            DesignTokens.Haptics.error()
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func restore() async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await subscriptionService.restorePurchases()
            DesignTokens.Haptics.success()
            // AppState will detect entitlement change and navigate away
        } catch {
            DesignTokens.Haptics.error()
            errorMessage = "No active subscription found. If you believe this is an error, please contact support."
            showError = true
        }
    }

    func selectProduct(_ product: Product) {
        DesignTokens.Haptics.selection()
        selectedProduct = product
    }

    // MARK: - Helpers

    func isYearly(_ product: Product) -> Bool {
        product.subscription?.subscriptionPeriod.unit == .year
    }

    func periodLabel(_ product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        switch period.unit {
        case .month: return "month"
        case .year: return "year"
        case .week: return "week"
        case .day: return "day"
        @unknown default: return ""
        }
    }

    func monthlyEquivalent(_ product: Product) -> String? {
        guard let period = product.subscription?.subscriptionPeriod,
              period.unit == .year else { return nil }

        let monthly = product.price / 12
        return monthly.formatted(.currency(code: product.priceFormatStyle.currencyCode))
    }

    private func trialPeriodText(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: return "\(period.value)-Day"
        case .week: return "\(period.value)-Week"
        case .month: return "\(period.value)-Month"
        case .year: return "\(period.value)-Year"
        @unknown default: return ""
        }
    }
}
