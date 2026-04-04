import SwiftUI
import SwiftData
import UIKit

@main
struct MACRAApp: App {
    @State private var themeManager = ThemeManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MealLog.self,
            MealItem.self,
            MacroGoal.self,
            UserProfile.self,
            SyncRecord.self,
            ExerciseEntry.self,
            WaterEntry.self,
            CaffeineEntry.self,
            WeightEntry.self,
            QuickMeal.self,
            GroupModel.self,
            ProgressPhoto.self,
            FoodProduct.self,
            Exercise.self,
            CompoundEntry.self,
            CompoundRegimen.self,
            VersusChallenge.self,
            FastingSession.self,
            AnalyticsEvent.self,
            UnlockedAchievement.self,
            AIConversation.self,
            AIConversationMessage.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.co.tamras.qyra")
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, delete the old store and retry with a fresh one
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            // Also remove WAL/SHM files
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                #if DEBUG
                fatalError("Could not create ModelContainer: \(error)")
                #else
                // Last resort: in-memory container so the app doesn't crash
                // swiftlint:disable:next force_try
                return try! ModelContainer(for: schema, configurations: [
                    ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                ])
                #endif
            }
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppGateView()
                .preferredColorScheme(themeManager.resolvedColorScheme)
                .environment(themeManager)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                AnalyticsService.shared.endSession()
                Task { await AnalyticsService.shared.flush() }
            case .active:
                Task { await AnalyticsService.shared.purgeOldEvents() }
            default:
                break
            }
        }
    }
}
