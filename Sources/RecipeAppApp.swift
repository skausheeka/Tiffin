import SwiftData
import SwiftUI

@main
struct RecipeAppApp: App {
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([Recipe.self, MealPlanEntry.self, CookingLogEntry.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(AppColor.accent)
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
