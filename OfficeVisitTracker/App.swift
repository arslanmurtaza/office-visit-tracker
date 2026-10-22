import SwiftUI
import SwiftData

@main
struct OfficeVisitTrackerApp: App {
    // Shared model container — persists on disk
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Place.self,
            Visit.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            // Store in the app's Documents folder (encrypted at rest)
            url: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first!
                .appendingPathComponent("OfficeVisitTracker.sqlite")
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(sharedModelContainer)
        }
        .commands {
            // Override the default "new item" command (no tables in this app)
            CommandGroup(replacing: .newItem) {}
        }
    }
}
