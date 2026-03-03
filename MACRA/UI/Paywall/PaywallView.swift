import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = SubscriptionViewModel()

    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(DesignTokens.Colors.textSecondary)
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
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 56))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .padding(.bottom, DesignTokens.Spacing.sm)

            Text("MACRA")
                .font(DesignTokens.Typography.largeTitle)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Premium Macro Intelligence")
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    // MARK: - Value Propositions

    private var valuePropositions: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            valueProp(icon: "camera.fill", text: "Instant food scanning with AI")
            valueProp(icon: "mic.fill", text: "Voice-powered meal logging")
            valueProp(icon: "heart.fill", text: "HealthKit activity integration")
            valueProp(icon: "chart.line.uptrend.xyaxis", text: "Smart insights and coaching")
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private func valueProp(icon: String, text: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .frame(width: 28)

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
                // Link to terms URL
            }
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.textTertiary)

            Text("·")
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            Button("Privacy Policy") {
                // Link to privacy URL
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
