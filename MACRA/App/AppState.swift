import Foundation
import SwiftData
import Observation

enum GateStatus: Equatable {
    case loading
    case needsAuth
    case needsSubscription
    case needsOnboarding
    case ready
}

@Observable
@MainActor
final class AppState {
    var gateStatus: GateStatus = .loading
    var isAuthenticated: Bool = false
    var isSubscribed: Bool = false
    var hasCompletedOnboarding: Bool = false

    let subscriptionService: SubscriptionService
    var modelContainer: ModelContainer?

    init(subscriptionService: SubscriptionService? = nil) {
        self.subscriptionService = subscriptionService ?? SubscriptionService.shared
    }

    func evaluateGate() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--skip-gate") {
            skipToReady()
            return
        }
        #endif

        // Check real auth state via Sign in with Apple
        await AuthService.shared.checkCredentialState()
        isAuthenticated = AuthService.shared.isSignedIn

        let subscribed = await subscriptionService.isSubscribed
        isSubscribed = subscribed

        if let container = modelContainer {
            let profileRepo = ProfileRepository(modelContainer: container)
            let swiftDataOnboarded = (try? await profileRepo.hasCompletedOnboarding()) ?? false
            let userDefaultsOnboarded = UserDefaults.standard.string(forKey: "onboarding_completed_at") != nil
            hasCompletedOnboarding = swiftDataOnboarded || userDefaultsOnboarded

            // Configure services with cache access
            NutritionService.shared.configure(modelContainer: container)
            ExerciseImportService.shared.configure(modelContainer: container)
            FoodAnalysisPipeline.shared.configure(modelContainer: container)
            AnalyticsService.shared.configure(modelContainer: container)
            AchievementEngine.shared.configure(modelContainer: container)

            // Auto-import exercise database on first launch (background)
            Task.detached(priority: .background) {
                await ExerciseImportService.shared.importIfNeeded()
            }

            // Retroactive data tagging — scope existing records to current user
            if let userId = CurrentUserProvider.shared.userId {
                Task.detached(priority: .background) {
                    let migrator = DataMigrationService(modelContainer: container)
                    await migrator.tagUnownedRecords(with: userId)
                }
            }
        }

        // Onboarding first — new users go straight into the full flow
        // (sign-in and paywall are steps within the onboarding itself)
        if !hasCompletedOnboarding {
            gateStatus = .needsAuth  // Show landing screen → "Get Started" → onboarding
            return
        }

        // Returning users who completed onboarding
        if !isAuthenticated {
            gateStatus = .needsAuth
            return
        }
        if !isSubscribed {
            gateStatus = .needsSubscription
            return
        }
        gateStatus = .ready
    }

    func signOut() {
        AuthService.shared.signOut()
        isAuthenticated = false
        gateStatus = .needsAuth
    }

    func handleSubscriptionChange() async {
        await evaluateGate()
    }

    func completeOnboarding() async {
        hasCompletedOnboarding = true

        // Persist to SwiftData so future app launches see the flag
        if let container = modelContainer {
            let profileRepo = ProfileRepository(modelContainer: container)
            try? await profileRepo.markOnboardingComplete()
        }

        // Skip full evaluateGate — go straight to ready
        // (auth/sub status doesn't matter for initial entry after onboarding)
        gateStatus = .ready
    }

    #if DEBUG
    func skipToReady() {
        isAuthenticated = true
        isSubscribed = true
        hasCompletedOnboarding = true
        gateStatus = .ready
    }
    #endif
}
