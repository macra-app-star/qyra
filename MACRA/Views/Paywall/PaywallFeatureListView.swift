import SwiftUI
import StoreKit

struct PaywallFeatureListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SubscriptionViewModel()
    @State private var selectedPlan: PlanType = .yearly
    @State private var showSuccessAlert = false
    @State private var showTerms = false
    @State private var showPrivacy = false

    private let termsURL = URL(string: "https://qyra.app/terms")!
    private let privacyURL = URL(string: "https://qyra.app/privacy")!

    enum PlanType: String, CaseIterable {
        case monthly
        case yearly
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    titleSection
                    featureList
                    planCards
                    billingDescription
                    continueButton
                    legalFooter
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
                .accessibilityLabel("Go back")
                .accessibilityAddTraits(.isButton)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.restore() }
                } label: {
                    if viewModel.isRestoring {
                        ProgressView()
                            .tint(DesignTokens.Colors.textTertiary)
                    } else {
                        Text("Restore")
                            .font(DesignTokens.Typography.medium(16))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }
                }
                .disabled(viewModel.isRestoring)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
        .alert("Welcome to Qyra!", isPresented: $showSuccessAlert) {
            Button("Continue") {
                dismiss()
            }
        }
        .task {
            await viewModel.loadProducts()
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                WebContentView(title: "Terms of Use", url: termsURL)
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

    // MARK: - Title

    private var titleSection: some View {
        Text("Unlock Qyra to reach your goals faster.")
            .font(DesignTokens.Typography.headlineFont(28))
            .foregroundStyle(DesignTokens.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DesignTokens.Spacing.lg)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            featureRow(
                title: "Easy food scanning",
                subtitle: "Take a photo of your food and we do the rest"
            )
            featureRow(
                title: "Get your dream body",
                subtitle: "Personalized meal plans tailored to your goals"
            )
            featureRow(
                title: "Track your progress",
                subtitle: "Detailed analytics to keep you on track"
            )
        }
    }

    private func featureRow(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(DesignTokens.Typography.icon(24))
                .foregroundStyle(DesignTokens.Colors.healthGreen)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(DesignTokens.Typography.semibold(16))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(subtitle)
                    .font(DesignTokens.Typography.bodyFont(14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
    }

    // MARK: - Plan Cards

    private var planCards: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            planCard(
                type: .monthly,
                priceLabel: "$9.99/mo",
                planLabel: "Monthly",
                subtitle: nil,
                badge: nil
            )

            planCard(
                type: .yearly,
                priceLabel: "$2.49/mo",
                planLabel: "Yearly",
                subtitle: "$29.99/year",
                badge: "SAVE 75%"
            )
        }
    }

    private func planCard(
        type: PlanType,
        priceLabel: String,
        planLabel: String,
        subtitle: String?,
        badge: String?
    ) -> some View {
        let isSelected = selectedPlan == type

        return Button {
            withAnimation(DesignTokens.Anim.quick) {
                selectedPlan = type
            }
        } label: {
            HStack {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected
                                ? DesignTokens.Colors.buttonPrimary
                                : DesignTokens.Colors.border,
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(DesignTokens.Colors.buttonPrimary)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text(planLabel)
                            .font(DesignTokens.Typography.semibold(16))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        if let badge {
                            Text(badge)
                                .font(DesignTokens.Typography.medium(11))
                                .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                                .padding(.horizontal, DesignTokens.Spacing.sm)
                                .padding(.vertical, DesignTokens.Spacing.xxs)
                                .background(DesignTokens.Colors.buttonPrimary)
                                .clipShape(Capsule())
                        }
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(DesignTokens.Typography.bodyFont(13))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }

                Spacer()

                Text(priceLabel)
                    .font(DesignTokens.Typography.semibold(17))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .stroke(
                        isSelected
                            ? DesignTokens.Colors.buttonPrimary
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Billing Description

    private var billingDescription: some View {
        Text(selectedPlan == .monthly
             ? "Billed monthly at $9.99"
             : "Billed annually at $29.99")
            .font(DesignTokens.Typography.bodyFont(14))
            .foregroundStyle(DesignTokens.Colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .animation(.none, value: selectedPlan)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            Task {
                await handlePurchase()
            }
        } label: {
            Group {
                if viewModel.isPurchasing {
                    ProgressView()
                        .tint(DesignTokens.Colors.buttonPrimaryText)
                } else {
                    Text("Continue")
                        .font(DesignTokens.Typography.semibold(17))
                        .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(DesignTokens.Colors.buttonPrimary)
            .clipShape(Capsule())
        }
        .disabled(viewModel.isPurchasing || viewModel.isLoading)
    }

    // MARK: - Legal Footer

    private var legalFooter: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Button("Terms of Use") {
                showTerms = true
            }
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.textTertiary)

            Text("\u{00B7}")
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            Button("Privacy Policy") {
                showPrivacy = true
            }
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
    }

    // MARK: - Purchase Logic

    private func handlePurchase() async {
        // Select the correct product based on plan type
        let targetProduct = viewModel.products.first { product in
            switch selectedPlan {
            case .monthly:
                return product.subscription?.subscriptionPeriod.unit == .month
            case .yearly:
                return product.subscription?.subscriptionPeriod.unit == .year
            }
        }

        guard let product = targetProduct else { return }
        viewModel.selectProduct(product)

        await viewModel.purchase()

        // If no error was shown, treat as success
        if !viewModel.showError && !viewModel.isPurchasing {
            showSuccessAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        PaywallFeatureListView()
    }
}
