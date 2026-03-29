import AuthenticationServices
import SwiftUI

enum WearableProvider: String, CaseIterable, Codable, Identifiable {
    case appleWatch = "apple_watch"
    case ouraRing = "oura"
    case whoop = "whoop"
    case fitbit = "fitbit"
    case garmin = "garmin"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleWatch: return "Apple Watch"
        case .ouraRing: return "Oura Ring"
        case .whoop: return "WHOOP"
        case .fitbit: return "Fitbit"
        case .garmin: return "Garmin"
        }
    }

    var iconName: String {
        switch self {
        case .appleWatch: return "applewatch"
        case .ouraRing: return "circle.dotted"
        case .whoop: return "waveform.path.ecg"
        case .fitbit: return "heart.circle"
        case .garmin: return "figure.run.circle"
        }
    }

    var brandColor: Color {
        switch self {
        case .appleWatch: return Color(hex: "1C1C1E")
        case .ouraRing: return Color(hex: "D4AF37")
        case .whoop: return Color(hex: "00B8D4")
        case .fitbit: return Color(hex: "00B0B9")
        case .garmin: return Color(hex: "007CC3")
        }
    }

    var authURL: String {
        switch self {
        case .appleWatch: return ""
        case .ouraRing: return "https://cloud.ouraring.com/oauth/authorize"
        case .whoop: return "https://api.prod.whoop.com/oauth/oauth2/auth"
        case .fitbit: return "https://www.fitbit.com/oauth2/authorize"
        case .garmin: return "https://connect.garmin.com/oauthConfirm"
        }
    }

    var tokenURL: String {
        switch self {
        case .appleWatch: return ""
        case .ouraRing: return "https://api.ouraring.com/oauth/token"
        case .whoop: return "https://api.prod.whoop.com/oauth/oauth2/token"
        case .fitbit: return "https://api.fitbit.com/oauth2/token"
        case .garmin: return "https://connectapi.garmin.com/oauth-service/oauth/token"
        }
    }

    var usesHealthKit: Bool {
        self == .appleWatch
    }

    var dataTypes: [WearableDataType] {
        switch self {
        case .appleWatch: return [.steps, .heartRate, .activeCalories, .sleep, .workouts, .hrv, .restingHR]
        case .ouraRing: return [.sleep, .heartRate, .hrv, .restingHR, .readiness, .steps, .activeCalories]
        case .whoop: return [.sleep, .strain, .recovery, .heartRate, .hrv, .workouts]
        case .fitbit: return [.steps, .heartRate, .sleep, .activeCalories, .workouts]
        case .garmin: return [.steps, .heartRate, .sleep, .activeCalories, .workouts, .stress]
        }
    }
}

enum WearableDataType: String, Codable {
    case steps, heartRate, activeCalories, sleep, workouts
    case hrv, restingHR, readiness, strain, recovery, stress

    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .heartRate: return "Heart Rate"
        case .activeCalories: return "Active Calories"
        case .sleep: return "Sleep"
        case .workouts: return "Workouts"
        case .hrv: return "HRV"
        case .restingHR: return "Resting HR"
        case .readiness: return "Readiness"
        case .strain: return "Strain"
        case .recovery: return "Recovery"
        case .stress: return "Stress"
        }
    }
}

@MainActor
@Observable
final class WearableService {
    static let shared = WearableService()

    var connectedProviders: [WearableProvider] = []
    var connectionStates: [WearableProvider: ConnectionState] = [:]
    var lastSyncTimes: [WearableProvider: Date] = [:]

    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case error(String)
    }

    private let keychain = KeychainService.shared

    init() {
        loadPersistedConnections()
    }

    func connect(_ provider: WearableProvider) async {
        if provider.usesHealthKit {
            await connectAppleWatch()
            return
        }
        await connectOAuth(provider)
    }

    private func connectAppleWatch() async {
        connectionStates[.appleWatch] = .connecting
        let authorized = await HealthKitService.shared.requestAuthorization()
        if authorized {
            connectionStates[.appleWatch] = .connected
            if !connectedProviders.contains(.appleWatch) {
                connectedProviders.append(.appleWatch)
            }
            lastSyncTimes[.appleWatch] = Date()
            persistConnections()
        } else {
            connectionStates[.appleWatch] = .error("Authorization denied")
        }
    }

    private func connectOAuth(_ provider: WearableProvider) async {
        connectionStates[provider] = .connecting

        // OAuth flow placeholder — requires ASWebAuthenticationSession
        // The redirect URI is: qyra://oauth/{provider.rawValue}
        // Token exchange happens via Supabase Edge Function to keep client secrets server-side
        // For now, store a placeholder connection state

        // Simulate a brief connection delay
        try? await Task.sleep(for: .milliseconds(800))

        // Check if we have an existing token
        if keychain.hasToken(for: "\(provider.rawValue)_access_token") {
            connectionStates[provider] = .connected
            if !connectedProviders.contains(provider) {
                connectedProviders.append(provider)
            }
            lastSyncTimes[provider] = Date()
            persistConnections()
        } else {
            // In production, this would launch ASWebAuthenticationSession
            connectionStates[provider] = .error("Coming soon")
        }
    }

    func disconnect(_ provider: WearableProvider) {
        keychain.deleteToken(for: "\(provider.rawValue)_access_token")
        keychain.deleteToken(for: "\(provider.rawValue)_refresh_token")
        connectedProviders.removeAll { $0 == provider }
        connectionStates[provider] = .disconnected
        lastSyncTimes.removeValue(forKey: provider)
        persistConnections()
    }

    func isConnected(_ provider: WearableProvider) -> Bool {
        connectionStates[provider] == .connected
    }

    // MARK: - Persistence

    private func persistConnections() {
        let rawValues = connectedProviders.map(\.rawValue)
        UserDefaults.standard.set(rawValues, forKey: "qyra_connected_wearables")
    }

    private func loadPersistedConnections() {
        guard let rawValues = UserDefaults.standard.stringArray(forKey: "qyra_connected_wearables") else { return }
        for raw in rawValues {
            guard let provider = WearableProvider(rawValue: raw) else { continue }
            connectedProviders.append(provider)
            connectionStates[provider] = .connected
        }
    }
}

struct WearableSyncResult {
    let provider: WearableProvider
    let stepsCount: Int?
    let sleepHours: Double?
    let activeCalories: Double?
    let restingHeartRate: Int?
    let hrv: Double?
    let lastSynced: Date
}
