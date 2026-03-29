import SwiftUI

struct PartnerConfig: Codable, Identifiable {
    let id: String
    let partnerId: String
    let partnerName: String
    let logoURL: String?
    let accentColorHex: String?
    let welcomeMessage: String?
    let subscriptionBypassed: Bool
    let features: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case partnerId = "partner_id"
        case partnerName = "partner_name"
        case logoURL = "logo_url"
        case accentColorHex = "accent_color"
        case welcomeMessage = "welcome_message"
        case subscriptionBypassed = "subscription_bypassed"
        case features
    }

    /// Converts the stored hex string into a SwiftUI Color.
    /// Uses the `Color(hex:)` extension defined in OnboardingTheme.
    var accentColor: Color? {
        guard let hex = accentColorHex else { return nil }
        return Color(hex: hex)
    }
}
