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
final class AppState {
    var gateStatus: GateStatus = .loading
    var isAuthenticated: Bool = false
    var isSubscribed: Bool = false
    var hasCompletedOnboarding: Bool = false

    func evaluateGate() {
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

    // For Phase 1 stub: skip auth and subscription checks
    func skipToReady() {
        isAuthenticated = true
        isSubscribed = true
        hasCompletedOnboarding = true
        gateStatus = .ready
    }
}
