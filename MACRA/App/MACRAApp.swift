import SwiftUI
import SwiftData

@main
struct MACRAApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MealLog.self,
            MealItem.self,
            MacroGoal.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.co.tamras.macra")
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppGateView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
