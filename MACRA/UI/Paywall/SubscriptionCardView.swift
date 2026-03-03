import SwiftUI
import StoreKit

struct SubscriptionCardView: View {
    let product: Product
    let isSelected: Bool
    let isYearly: Bool
    let savingsText: String?
    let monthlyEquivalent: String?
    let periodLabel: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Text(product.displayName)
                                .font(DesignTokens.Typography.headline)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)

                            if isYearly, let savings = savingsText {
                                Text(savings)
                                    .font(DesignTokens.Typography.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, DesignTokens.Spacing.sm)
                                    .padding(.vertical, DesignTokens.Spacing.xxs)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            }
                        }

                        Text("\(product.displayPrice) / \(periodLabel)")
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)

                        if let monthly = monthlyEquivalent {
                            Text("\(monthly) / month")
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.Colors.textTertiary)
                        }

                        if let intro = product.subscription?.introductoryOffer,
                           intro.paymentMode == .freeTrial {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 12))
                                Text("\(intro.period.value)-day free trial")
                                    .font(DesignTokens.Typography.caption)
                            }
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    }

                    Spacer()

                    // Selection indicator
                    ZStack {
                        Circle()
                            .strokeBorder(
                                isSelected ? DesignTokens.Colors.accent : DesignTokens.Colors.border,
                                lineWidth: 2
                            )
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(DesignTokens.Colors.accent)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(isSelected ? DesignTokens.Colors.surfaceElevated : DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .strokeBorder(
                        isSelected ? DesignTokens.Colors.accent : DesignTokens.Colors.border,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(DesignTokens.Anim.quick, value: isSelected)
    }
}
