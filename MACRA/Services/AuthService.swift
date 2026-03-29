import AuthenticationServices
import Security
import os

@Observable
@MainActor
final class AuthService: NSObject {
    static let shared = AuthService()

    var isSignedIn: Bool = false
    var currentUserId: String?
    var currentUserName: String?
    var errorMessage: String?

    /// Supabase JWT access token (loaded from Keychain on launch)
    private(set) var supabaseAccessToken: String?

    private var signInContinuation: CheckedContinuation<Bool, Never>?
    private let logger = Logger(subsystem: "co.tamras.qyra", category: "Auth")

    private let keychainService = "co.tamras.qyra.auth"
    private let userIdKey = "apple_user_id"
    private let userNameKey = "apple_user_name"

    override init() {
        super.init()
        loadCredentials()
        restoreSupabaseSession()
    }

    // MARK: - Supabase Session Persistence

    /// Persist Supabase access + refresh tokens to Keychain after auth exchange
    func saveSupabaseTokens(accessToken: String, refreshToken: String) {
        let keychain = KeychainService.shared
        keychain.saveToken(accessToken, for: KeychainService.supabaseAccessToken)
        keychain.saveToken(refreshToken, for: KeychainService.supabaseRefreshToken)
        supabaseAccessToken = accessToken
        logger.info("Supabase tokens saved to Keychain")
    }

    /// Restore Supabase session from Keychain on app launch
    private func restoreSupabaseSession() {
        let keychain = KeychainService.shared
        if let accessToken = keychain.getToken(for: KeychainService.supabaseAccessToken) {
            supabaseAccessToken = accessToken
            logger.info("Supabase session restored from Keychain")
        }
    }

    /// Clear Supabase tokens (called on sign-out)
    private func clearSupabaseSession() {
        KeychainService.shared.clearSupabaseTokens()
        supabaseAccessToken = nil
        logger.info("Supabase session cleared")
    }

    // MARK: - Sign In

    func signIn() async -> Bool {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self

        return await withCheckedContinuation { continuation in
            signInContinuation = continuation
            controller.performRequests()
        }
    }

    // MARK: - Sign Out

    func signOut() {
        deleteKeychain(key: userIdKey)
        deleteKeychain(key: userNameKey)
        clearSupabaseSession()
        currentUserId = nil
        currentUserName = nil
        isSignedIn = false
        CurrentUserProvider.shared.clearUser()
        CurrentUserProvider.clearUserScopedDefaults()
        UserDefaults.standard.removeObject(forKey: "qyra.lastSyncDate")
        AnalyticsService.shared.endSession()
    }

    // MARK: - Credential Check

    func checkCredentialState() async {
        guard let userId = currentUserId else {
            isSignedIn = false
            return
        }

        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userId)
            isSignedIn = (state == .authorized)
        } catch {
            isSignedIn = false
        }
    }

    // MARK: - Keychain

    private func loadCredentials() {
        if let userId = readKeychain(key: userIdKey) {
            currentUserId = userId
            currentUserName = readKeychain(key: userNameKey)
            isSignedIn = true
        }
    }

    private func saveKeychain(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func readKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userId = credential.user
                saveKeychain(key: userIdKey, value: userId)
                currentUserId = userId

                if let name = credential.fullName {
                    let fullName = [name.givenName, name.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    if !fullName.isEmpty {
                        saveKeychain(key: userNameKey, value: fullName)
                        currentUserName = fullName
                    }
                }

                isSignedIn = true
                CurrentUserProvider.shared.setUser(id: userId)
                signInContinuation?.resume(returning: true)
                signInContinuation = nil
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
            signInContinuation?.resume(returning: false)
            signInContinuation = nil
        }
    }
}
