import SwiftUI
import StoreKit

struct OnboardingPaywallView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var subVM = SubscriptionViewModel()
    @State private var purchaseSucceeded = false

    private let features = [
        "Unlimited meal logging",
        "AI-powered food recognition",
        "Personalized macro targets",
        "Progress tracking & insights",
        "HealthKit integration"
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Title
                    VStack(spacing: DesignTokens.Layout.tightGap) {
                        Text("Unlock Qyra")
                            .font(OnboardingTheme.titleFont)
                            .tracking(OnboardingTheme.titleTracking)
                            .foregroundStyle(OnboardingTheme.textPrimary)

                        Text("Start your free trial today")
                            .font(OnboardingTheme.subtitleFont)
                            .foregroundStyle(OnboardingTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, DesignTokens.Layout.sectionGap)

                    // Features list
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: DesignTokens.Layout.itemGap) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(QyraFont.regular(20))
                                    .foregroundStyle(Color.accentColor)

                                Text(feature)
                                    .font(QyraFont.medium(16))
                                    .foregroundStyle(OnboardingTheme.textPrimary)
                            }
                        }
                    }
                    .padding(.horizontal, OnboardingTheme.screenPadding)
                    .padding(.top, 28)

                    // Real StoreKit products
                    if subVM.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if subVM.products.isEmpty {
                        // Fallback: show static pricing if StoreKit fails
                        staticPricingCards
                            .padding(.top, 28)
                    } else {
                        // Real product cards from App Store Connect
                        VStack(spacing: OnboardingTheme.optionCardSpacing) {
                            ForEach(subVM.products.sorted { isYearlyFirst($0, $1) }, id: \.id) { product in
                                productCard(product)
                            }
                        }
                        .padding(.horizontal, OnboardingTheme.screenPadding)
                        .padding(.top, 28)
                    }
                }
            }

            // CTA + Restore
            VStack(spacing: DesignTokens.Layout.itemGap) {
                // Purchase button
                OnboardingContinueButton(
                    label: subVM.isPurchasing ? "Processing..." : subVM.purchaseButtonTitle,
                    isEnabled: subVM.canPurchase
                ) {
                    Task {
                        await subVM.purchase()
                        // Check if purchase succeeded
                        if await SubscriptionService.shared.isSubscribed {
                            purchaseSucceeded = true
                            viewModel.advance()
                        }
                    }
                }

                // Restore + Skip
                HStack(spacing: 24) {
                    Button {
                        Task {
                            await subVM.restore()
                            if await SubscriptionService.shared.isSubscribed {
                                viewModel.advance()
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(QyraFont.medium(14))
                            .foregroundStyle(OnboardingTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .disabled(subVM.isRestoring)

                    Button {
                        viewModel.advance()
                    } label: {
                        Text("Skip")
                            .font(QyraFont.medium(14))
                            .foregroundStyle(OnboardingTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, DesignTokens.Layout.tightGap)
            }
        }
        .alert("Error", isPresented: $subVM.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let msg = subVM.errorMessage {
                Text(msg)
            }
        }
        .task {
            await subVM.loadProducts()
        }
    }

    // MARK: - Product Card (Real StoreKit)

    private func productCard(_ product: Product) -> some View {
        let isSelected = subVM.selectedProduct?.id == product.id
        let isYearly = subVM.isYearly(product)

        return Button {
            DesignTokens.Haptics.selection()
            subVM.selectProduct(product)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isYearly ? "Yearly" : "Monthly")
                        .font(QyraFont.semibold(17))
                        .foregroundStyle(isSelected ? .white : OnboardingTheme.textPrimary)

                    if isYearly, let savings = subVM.savingsText {
                        Text(savings)
                            .font(QyraFont.medium(13))
                            .foregroundStyle(isSelected ? OnboardingTheme.accent : Color.accentColor)
                    }

                    if isYearly, let monthly = subVM.monthlyEquivalent(product) {
                        Text("\(monthly)/mo")
                            .font(QyraFont.regular(12))
                            .foregroundStyle(isSelected ? .white.opacity(0.7) : OnboardingTheme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(QyraFont.bold(17))
                        .foregroundStyle(isSelected ? .white : OnboardingTheme.textPrimary)

                    Text("/\(subVM.periodLabel(product))")
                        .font(QyraFont.regular(13))
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : OnboardingTheme.textSecondary)
                }
            }
            .padding(.horizontal, DesignTokens.Layout.screenMargin)
            .frame(minHeight: 72)
            .background(
                RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius)
                    .fill(isSelected ? Color.accentColor : OnboardingTheme.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius)
                    .strokeBorder(isSelected ? Color.accentColor : OnboardingTheme.divider, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Static Fallback (if StoreKit fails to load)

    private var staticPricingCards: some View {
        VStack(spacing: OnboardingTheme.optionCardSpacing) {
            staticCard(label: "Monthly", price: "$9.99/mo", savings: nil, isSelected: false)
            staticCard(label: "Yearly", price: "$29.99/yr", savings: "Save 75%", isSelected: true)
        }
        .padding(.horizontal, OnboardingTheme.screenPadding)
    }

    private func staticCard(label: String, price: String, savings: String?, isSelected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(QyraFont.semibold(17))
                    .foregroundStyle(isSelected ? .white : OnboardingTheme.textPrimary)
                if let savings {
                    Text(savings)
                        .font(QyraFont.medium(13))
                        .foregroundStyle(isSelected ? OnboardingTheme.accent : Color.accentColor)
                }
            }
            Spacer()
            Text(price)
                .font(QyraFont.bold(17))
                .foregroundStyle(isSelected ? .white : OnboardingTheme.textPrimary)
        }
        .padding(.horizontal, DesignTokens.Layout.screenMargin)
        .frame(minHeight: OnboardingTheme.optionCardHeight)
        .background(
            RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius)
                .fill(isSelected ? Color.accentColor : OnboardingTheme.backgroundSecondary)
        )
    }

    // MARK: - Helpers

    private func isYearlyFirst(_ a: Product, _ b: Product) -> Bool {
        let aIsYearly = a.subscription?.subscriptionPeriod.unit == .year
        let bIsYearly = b.subscription?.subscriptionPeriod.unit == .year
        if aIsYearly && !bIsYearly { return false } // yearly goes second (below monthly)
        if !aIsYearly && bIsYearly { return true }
        return a.price < b.price
    }
}

#Preview {
    OnboardingPaywallView(viewModel: .preview)
}
