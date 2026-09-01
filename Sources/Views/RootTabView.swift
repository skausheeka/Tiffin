import SwiftData
import SwiftUI

private enum AppTab: Hashable {
    case recipes, mealPlan, leaderboard, discover, profile
}

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .recipes
    @State private var router = CookLogDeepLinkRouter.shared
    @State private var recipeToLog: Recipe?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Recipes", systemImage: "fork.knife", value: AppTab.recipes) {
                RecipeListView()
            }

            Tab("Meal Plan", systemImage: "calendar", value: AppTab.mealPlan) {
                MealPlanView()
            }

            Tab("Leaderboard", systemImage: "star.fill", value: AppTab.leaderboard) {
                LeaderboardView()
            }

            Tab("Discover", systemImage: "sparkle.magnifyingglass", value: AppTab.discover) {
                PlaceholderTabView(title: "Discover", systemImage: "sparkle.magnifyingglass")
            }
            .disabled(true)

            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                PlaceholderTabView(title: "Profile", systemImage: "person.crop.circle")
            }
            .disabled(true)
        }
        .toolbarBackground(AppColor.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(item: $recipeToLog) { recipe in
            CookingLogEntryFormView(preselectedRecipe: recipe)
        }
        .onChange(of: router.pendingEntryID) { _, newValue in
            guard let newValue else { return }
            router.pendingEntryID = nil
            let id = newValue
            let descriptor = FetchDescriptor<MealPlanEntry>(predicate: #Predicate { $0.id == id })
            if let entry = try? modelContext.fetch(descriptor).first {
                recipeToLog = entry.recipe
            }
        }
    }
}

private struct PlaceholderTabView: View {
    let title: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: systemImage, description: Text("Coming in a later phase."))
                .navigationTitle(title)
                .background(AppColor.background)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        GlobalAddMenu()
                    }
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Recipe.self, MealPlanEntry.self, CookingLogEntry.self], inMemory: true)
}
