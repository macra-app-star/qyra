import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = SubscriptionViewModel()
    @State private var showTerms = false
    @State private var showPrivacy = false

    private let termsURL = URL(string: "https://qyra.app/terms")!
    private let privacyURL = URL(string: "https://qyra.app/privacy")!

    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(DesignTokens.Colors.textSecondary)
            } else if viewModel.products.isEmpty {
                emptyProductsView
            } else {
                scrollContent
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
        .task {
            await viewModel.loadProducts()
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                WebContentView(title: "Terms of Service", url: termsURL)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showTerms = false }
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack {
                WebContentView(title: "Privacy Policy", url: privacyURL)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showPrivacy = false }
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Empty Products

    private var emptyProductsView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(QyraFont.regular(40))
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            Text("Couldn't load subscriptions")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Please check your connection and try again")
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .multilineTextAlignment(.center)

            MonochromeButton("Retry", icon: "arrow.clockwise", style: .secondary) {
                Task { await viewModel.loadProducts() }
            }
            .frame(maxWidth: 200)

            #if DEBUG
            MonochromeButton("Skip (Dev)", icon: "forward.fill", style: .ghost) {
                appState.skipToReady()
            }
            .frame(maxWidth: 200)
            #endif
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }

    // MARK: - Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()
                    .frame(height: DesignTokens.Spacing.lg)

                logoSection
                valuePropositions
                subscriptionCards
                purchaseButton
                restoreButton

                #if DEBUG
                MonochromeButton("Skip Paywall (Dev)", icon: "forward.fill", style: .ghost) {
                    appState.skipToReady()
                }
                #endif

                legalLinks

                Spacer()
                    .frame(height: DesignTokens.Spacing.lg)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text("Qyra")
                .font(QyraFont.bold(48))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .padding(.bottom, DesignTokens.Spacing.sm)

            Text("Premium Macro Intelligence")
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    // MARK: - Value Propositions

    private var valuePropositions: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            valueProp(icon: "camera.fill", text: "Instant food scanning with AI", color: DesignTokens.Colors.brandAccent)
            valueProp(icon: "mic.fill", text: "Voice-powered meal logging", color: DesignTokens.Colors.fat)
            valueProp(icon: "heart.fill", text: "HealthKit activity integration", color: DesignTokens.Colors.protein)
            valueProp(icon: "chart.line.uptrend.xyaxis", text: "Smart insights and coaching", color: DesignTokens.Colors.aiAccent)
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private func valueProp(icon: String, text: String, color: Color = DesignTokens.Colors.brandAccent) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(QyraFont.semibold(16))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))

            Text(text)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
    }

    // MARK: - Subscription Cards

    private var subscriptionCards: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(viewModel.products, id: \.id) { product in
                SubscriptionCardView(
                    product: product,
                    isSelected: viewModel.selectedProduct?.id == product.id,
                    isYearly: viewModel.isYearly(product),
                    savingsText: viewModel.isYearly(product) ? viewModel.savingsText : nil,
                    monthlyEquivalent: viewModel.monthlyEquivalent(product),
                    periodLabel: viewModel.periodLabel(product),
                    onSelect: { viewModel.selectProduct(product) }
                )
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        MonochromeButton(
            viewModel.purchaseButtonTitle,
            icon: "star.fill",
            style: .primary,
            isLoading: viewModel.isPurchasing
        ) {
            Task {
                await viewModel.purchase()
                await appState.handleSubscriptionChange()
            }
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task {
                await viewModel.restore()
                await appState.handleSubscriptionChange()
            }
        } label: {
            if viewModel.isRestoring {
                ProgressView()
                    .tint(DesignTokens.Colors.textTertiary)
            } else {
                Text("Restore Purchases")
                    .font(DesignTokens.Typography.footnote)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .disabled(viewModel.isRestoring)
    }

    // MARK: - Legal Links

    private var legalLinks: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Button("Terms of Service") {
                showTerms = true
            }
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.textTertiary)

            Text("·")
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            Button("Privacy Policy") {
                showPrivacy = true
            }
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
    }
}

#Preview {
    PaywallView()
        .environment(AppState())
}
