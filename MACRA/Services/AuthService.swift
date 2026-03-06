import AuthenticationServices
import Security

@Observable
@MainActor
final class AuthService: NSObject {
    static let shared = AuthService()

    var isSignedIn: Bool = false
    var currentUserId: String?
    var currentUserName: String?
    var errorMessage: String?

    private var signInContinuation: CheckedContinuation<Bool, Never>?

    private let keychainService = "co.tamras.macra.auth"
    private let userIdKey = "apple_user_id"
    private let userNameKey = "apple_user_name"

    override init() {
        super.init()
        loadCredentials()
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
        currentUserId = nil
        currentUserName = nil
        isSignedIn = false
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
