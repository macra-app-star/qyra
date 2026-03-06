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

    private let subscriptionService: SubscriptionService
    var modelContainer: ModelContainer?

    init(subscriptionService: SubscriptionService = SubscriptionService()) {
        self.subscriptionService = subscriptionService
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
            hasCompletedOnboarding = (try? await profileRepo.hasCompletedOnboarding()) ?? false
        }

        if !isAuthenticated {
            gateStatus = .needsAuth
            return
        }
        if !isSubscribed {
            gateStatus = .needsSubscription
            return
        }
        if !hasCompletedOnboarding {
            gateStatus = .needsOnboarding
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
        await evaluateGate()
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
