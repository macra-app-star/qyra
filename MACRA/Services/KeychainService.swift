import Foundation
import Security

final class KeychainService: Sendable {
    static let shared = KeychainService()

    private let serviceName = "com.qyra.app"

    // MARK: - Supabase Session Keys

    static let supabaseAccessToken  = "qyra.supabase.access_token"
    static let supabaseRefreshToken = "qyra.supabase.refresh_token"

    // MARK: - Save

    func saveToken(_ token: String, for key: String) {
        guard let data = token.data(using: .utf8) else { return }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    // MARK: - Load

    func getToken(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Delete

    func deleteToken(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Helpers

    func hasToken(for key: String) -> Bool {
        getToken(for: key) != nil
    }

    /// Remove all Supabase session tokens (call on sign-out)
    func clearSupabaseTokens() {
        deleteToken(for: Self.supabaseAccessToken)
        deleteToken(for: Self.supabaseRefreshToken)
    }
}
