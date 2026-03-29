import SwiftUI

@Observable @MainActor
class PartnerService {
    static let shared = PartnerService()

    private(set) var currentPartner: PartnerConfig?
    var isValidating = false
    var validationError: String?

    private let partnerKeychainKey = "qyra_partner_config"

    init() {
        loadStoredPartner()
    }

    /// Validate a partner code against the server
    func validateCode(_ code: String) async -> Bool {
        isValidating = true
        validationError = nil
        defer { isValidating = false }

        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else {
            validationError = "Please enter a partner code"
            return false
        }

        // TODO: Validate partner codes via Supabase partners table
        // For now, partner codes are disabled until server-side validation is implemented
        validationError = "Partner codes are not yet available"
        return false
    }

    func clearPartner() {
        currentPartner = nil
        KeychainService.shared.deleteToken(for: partnerKeychainKey)
    }

    var isPartnerUser: Bool { currentPartner != nil }
    var shouldBypassPaywall: Bool { currentPartner?.subscriptionBypassed == true }

    // MARK: - Persistence (Keychain)

    private func storePartner(_ config: PartnerConfig) {
        if let data = try? JSONEncoder().encode(config),
           let jsonString = String(data: data, encoding: .utf8) {
            KeychainService.shared.saveToken(jsonString, for: partnerKeychainKey)
        }
    }

    private func loadStoredPartner() {
        guard let jsonString = KeychainService.shared.getToken(for: partnerKeychainKey),
              let data = jsonString.data(using: .utf8),
              let config = try? JSONDecoder().decode(PartnerConfig.self, from: data) else { return }
        currentPartner = config
    }
}
