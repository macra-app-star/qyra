import Foundation
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

    init(subscriptionService: SubscriptionService = SubscriptionService()) {
        self.subscriptionService = subscriptionService
    }

    func evaluateGate() async {
        // Phase 2: Skip auth (Phase 4) and onboarding (Phase 3) — go straight to subscription check
        isAuthenticated = true
        hasCompletedOnboarding = true

        let subscribed = await subscriptionService.isSubscribed
        isSubscribed = subscribed

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

    func handleSubscriptionChange() async {
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
