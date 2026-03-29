import SwiftUI

enum QyraButtonStyle {
    case primary
    case secondary
    case ghost
    case destructive
}

// Keep typealias for backward compatibility
typealias MonochromeButtonStyle = QyraButtonStyle

struct MonochromeButton: View {
    let title: String
    let icon: String?
    let style: QyraButtonStyle
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: QyraButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(QyraFont.semibold(16))
                    }
                    Text(title)
                        .font(DesignTokens.Typography.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(textColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .strokeBorder(borderColor, lineWidth: hasBorder ? 1.5 : 0)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
    }

    private var textColor: Color {
        switch style {
        case .primary: return DesignTokens.Colors.buttonPrimaryText
        case .secondary: return DesignTokens.Colors.textPrimary
        case .ghost: return DesignTokens.Colors.textPrimary
        case .destructive: return .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return DesignTokens.Colors.buttonPrimary
        case .secondary: return .clear
        case .ghost: return .clear
        case .destructive: return DesignTokens.Colors.destructive
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return DesignTokens.Colors.border
        case .ghost: return .clear
        case .destructive: return .clear
        }
    }

    private var hasBorder: Bool {
        style == .secondary
    }
}

#Preview {
    VStack(spacing: DesignTokens.Layout.cardGap) {
        MonochromeButton("Subscribe", icon: "star.fill", style: .primary) {}
        MonochromeButton("Restore Purchases", style: .secondary) {}
        MonochromeButton("Skip", style: .ghost) {}
        MonochromeButton("Delete Account", icon: "trash", style: .destructive) {}
        MonochromeButton("Loading...", style: .primary, isLoading: true) {}
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
