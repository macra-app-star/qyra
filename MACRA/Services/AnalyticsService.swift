import Foundation
import SwiftData
import UIKit
import os

@MainActor
final class AnalyticsService: ObservableObject {

    static let shared = AnalyticsService()

    private let sessionId: String = UUID().uuidString
    private var sessionStartTime: Date = Date()
    private var repository: AnalyticsRepository?
    private let logger = Logger(subsystem: "co.tamras.qyra", category: "Analytics")

    // MARK: - Event Definitions

    enum Event: String {
        // Lifecycle
        case appSessionStart = "app_session_start"
        case appSessionEnd = "app_session_end"

        // Onboarding
        case onboardingStepCompleted = "onboarding_step_completed"
        case onboardingCompleted = "onboarding_completed"
        case onboardingDropoff = "onboarding_dropoff"

        // Meals & Scanning
        case mealLogged = "meal_logged"
        case scanCompleted = "scan_completed"
        case scanFailed = "scan_failed"
        case scanCorrected = "scan_corrected"
        case quickAddUsed = "quick_add_used"
        case barcodeScanned = "barcode_scanned"

        // Exercise
        case workoutStarted = "workout_started"
        case workoutCompleted = "workout_completed"
        case workoutAbandoned = "workout_abandoned"
        case exerciseAdded = "exercise_added"

        // Social
        case challengeCreated = "challenge_created"
        case challengeAccepted = "challenge_accepted"
        case groupCreated = "group_created"
        case groupJoined = "group_joined"

        // Subscription
        case paywallViewed = "paywall_viewed"
        case subscriptionStarted = "subscription_started"
        case premiumFeatureBlocked = "premium_feature_blocked"

        // Retention
        case streakMilestone = "streak_milestone"
        case streakBroken = "streak_broken"
        case featureOpened = "feature_opened"
    }

    // MARK: - Setup

    func configure(modelContainer: ModelContainer) {
        self.repository = AnalyticsRepository(modelContainer: modelContainer)
        logger.info("AnalyticsService configured with session: \(self.sessionId)")
        track(.appSessionStart)
    }

    // MARK: - Tracking

    func track(_ event: Event, properties: [String: String] = [:]) {
        var props = properties
        props["session_id"] = sessionId

        Task {
            guard let repository else {
                logger.warning("AnalyticsRepository not configured, dropping event: \(event.rawValue)")
                return
            }
            do {
                try await repository.recordEvent(
                    name: event.rawValue,
                    properties: props,
                    sessionId: sessionId,
                    userId: currentUserId()
                )
                #if DEBUG
                logger.debug("Tracked: \(event.rawValue) \(props.filter { $0.key != "session_id" })")
                #endif

                // Auto-flush when queue exceeds 20 events
                let count = try await repository.totalUnsyncedCount()
                if count >= 20 {
                    await flush()
                }
            } catch {
                logger.error("Failed to track \(event.rawValue): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Session

    func endSession() {
        let duration = Date().timeIntervalSince(sessionStartTime)
        track(.appSessionEnd, properties: [
            "duration_seconds": String(Int(duration))
        ])
    }

    // MARK: - Flush (Phase 20B will implement Supabase POST)

    func flush() async {
        guard let repository else { return }
        do {
            let pending = try await repository.pendingEvents(limit: 50)
            guard !pending.isEmpty else { return }

            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

            let payload: [[String: Any]] = pending.map { event in
                [
                    "name": event.name,
                    "properties": event.decodedProperties,
                    "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
                    "session_id": event.sessionId,
                    "user_id": event.userId as Any,
                    "device_id": deviceId
                ]
            }

            let body = try JSONSerialization.data(withJSONObject: ["events": payload])

            guard let url = URL(string: SupabaseConfig.functionsURL("analytics-ingest")) else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

            if let token = SupabaseConfig.authToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let syncedIds = pending.map(\.id)
                try await repository.markSynced(ids: syncedIds)
                logger.info("Flushed \(pending.count) analytics events to Supabase")
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                logger.warning("Analytics flush returned status \(statusCode)")
            }
        } catch {
            logger.error("Flush failed: \(error.localizedDescription)")
        }
    }

    func purgeOldEvents() async {
        guard let repository else { return }
        do {
            try await repository.purgeOldSyncedEvents(olderThan: 30)
        } catch {
            logger.error("Purge failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func currentUserId() -> String? {
        // Match existing auth pattern — AuthService stores in Keychain
        AuthService.shared.currentUserId
    }
}
