import SwiftUI

// MARK: - Simple Option Card (text only)

struct OnboardingOptionCard: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            DesignTokens.Haptics.selection()
            action()
        }) {
            Text(label)
                .font(OnboardingTheme.cardLabelFont)
                .foregroundStyle(isSelected ? OnboardingTheme.selectedCardText : OnboardingTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, OnboardingTheme.cardPadding)
                .padding(.vertical, 18)
                .background(isSelected ? OnboardingTheme.selectedCardBg : OnboardingTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Icon + Label Option Card

struct OnboardingIconOptionCard: View {
    let icon: String
    let isEmoji: Bool
    let label: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        icon: String,
        isEmoji: Bool = false,
        label: String,
        subtitle: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.isEmoji = isEmoji
        self.label = label
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: {
            DesignTokens.Haptics.selection()
            action()
        }) {
            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(isSelected ? OnboardingTheme.selectedCardText : OnboardingTheme.backgroundSecondary)
                        .frame(width: 36, height: 36)

                    if isEmoji {
                        Text(icon)
                            .font(QyraFont.regular(24))
                    } else {
                        Image(systemName: icon)
                            .font(QyraFont.regular(22))
                            .foregroundStyle(isSelected ? OnboardingTheme.textPrimary : OnboardingTheme.textSecondary)
                    }
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(OnboardingTheme.cardLabelFont)
                        .foregroundStyle(isSelected ? OnboardingTheme.selectedCardText : OnboardingTheme.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(QyraFont.regular(14))
                            .foregroundStyle(
                                isSelected
                                    ? OnboardingTheme.selectedCardText.opacity(0.7)
                                    : OnboardingTheme.textSecondary
                            )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, OnboardingTheme.cardPadding)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? OnboardingTheme.selectedCardBg : OnboardingTheme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    VStack(spacing: DesignTokens.Layout.itemGap) {
        OnboardingOptionCard(label: "Male", isSelected: true) { }
        OnboardingOptionCard(label: "Female", isSelected: false) { }
        OnboardingIconOptionCard(icon: "circle.fill", label: "0-2", subtitle: "Workouts now and then", isSelected: false) { }
        OnboardingIconOptionCard(icon: "circle.fill", label: "3-5", subtitle: "A few workouts per week", isSelected: true) { }
    }
    .padding()
}
