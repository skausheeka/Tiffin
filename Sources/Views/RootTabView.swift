import SwiftUI

private enum AppTab: Hashable {
    case recipes, mealPlan, add, discover, profile
}

struct RootTabView: View {
    @State private var selectedTab: AppTab = .recipes
    @State private var isPresentingAddRecipe = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Recipes", systemImage: "fork.knife", value: AppTab.recipes) {
                RecipeListView()
            }

            Tab("Meal Plan", systemImage: "calendar", value: AppTab.mealPlan) {
                PlaceholderTabView(title: "Meal Plan", systemImage: "calendar")
            }
            .disabled(true)

            Tab("Add", systemImage: "plus.circle.fill", value: AppTab.add) {
                Color.clear
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
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .add {
                isPresentingAddRecipe = true
                selectedTab = oldValue
            }
        }
        .sheet(isPresented: $isPresentingAddRecipe) {
            AddRecipeView()
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
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
