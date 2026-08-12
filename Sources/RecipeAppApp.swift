import SwiftData
import SwiftUI

@main
struct RecipeAppApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(AppColor.accent)
        }
        .modelContainer(for: [Recipe.self, MealPlanEntry.self])
    }
}
