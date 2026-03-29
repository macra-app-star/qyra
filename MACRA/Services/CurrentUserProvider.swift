import Foundation
import os

/// Single source of truth for the currently authenticated user's identity.
/// All SwiftData queries and writes must use this to scope data to the correct account.
@MainActor
final class CurrentUserProvider: ObservableObject {

    static let shared = CurrentUserProvider()

    private let logger = Logger(subsystem: "co.tamras.qyra", category: "Auth")

    /// The authenticated user's ID. Nil means no user is logged in.
    @Published private(set) var userId: String?

    /// A non-optional version for SwiftData predicates. Returns device-scoped ID if not logged in.
    var requiredUserId: String {
        userId ?? "anonymous_\(deviceId)"
    }

    /// Stable device identifier for anonymous/pre-auth data
    let deviceId: String = {
        if let existing = UserDefaults.standard.string(forKey: "qyra_device_id") {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "qyra_device_id")
        return newId
    }()

    private init() {
        // AuthService stores userId in Keychain under "apple_user_id"
        self.userId = AuthService.shared.currentUserId
        logger.info("CurrentUserProvider initialized. userId: \(self.userId ?? "nil")")
    }

    /// Called after successful authentication
    func setUser(id: String) {
        self.userId = id
        logger.info("User set: \(id)")
        NotificationCenter.default.post(name: .userDidChange, object: nil, userInfo: ["userId": id])
    }

    /// Called on logout — clears active user but does NOT delete data
    func clearUser() {
        let previousId = userId
        self.userId = nil
        logger.info("User cleared. Previous: \(previousId ?? "nil")")
        NotificationCenter.default.post(name: .userDidChange, object: nil)
    }

    /// Keys that are USER-specific and must be cleared on logout
    static let userScopedKeys: [String] = [
        "firstName", "lastName", "username",
        "hasCompletedOnboarding",
        "onboarding_referral_source", "onboarding_tried_other_apps",
        "onboarding_has_coach", "onboarding_diet_type",
        "onboarding_barrier", "onboarding_accomplishment",
        "onboarding_completed_at",
        "addBurnedCalories", "rolloverCalories",
        "cycleTrackingEnabled",
        "workoutReminderEnabled", "workoutReminderHour", "workoutReminderMinute",
        "badgeCelebrations", "liveActivity", "autoAdjustMacros",
        "qyra.lastSyncDate"
    ]

    static func clearUserScopedDefaults() {
        for key in userScopedKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

extension Notification.Name {
    static let userDidChange = Notification.Name("co.tamras.qyra.userDidChange")
}
