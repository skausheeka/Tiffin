import SwiftUI

private enum AppTab: Hashable {
    case recipes, mealPlan, leaderboard, discover, profile
}

struct RootTabView: View {
    @State private var selectedTab: AppTab = .recipes

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Recipes", systemImage: "fork.knife", value: AppTab.recipes) {
                RecipeListView()
            }

            Tab("Meal Plan", systemImage: "calendar", value: AppTab.mealPlan) {
                PlaceholderTabView(title: "Meal Plan", systemImage: "calendar")
            }
            .disabled(true)

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
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
