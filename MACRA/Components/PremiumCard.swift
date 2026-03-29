import SwiftUI

struct PremiumCard: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func premiumCard(
        cornerRadius: CGFloat = 12,
        elevation: PremiumCard.Elevation = .standard
    ) -> some View {
        modifier(PremiumCard(cornerRadius: cornerRadius))
    }
}

extension PremiumCard {
    // Keep Elevation enum so callers don't break, but it's ignored now
    enum Elevation {
        case subtle, standard, elevated
    }
}
