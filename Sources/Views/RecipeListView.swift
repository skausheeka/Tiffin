import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var isPresentingFilters = false
    @State private var recipeFilter = RecipeFilter()
    @State private var path = NavigationPath()
    @State private var recipePendingDelete: Recipe?

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var filteredRecipes: [Recipe] {
        recipes
            .filter { recipe in
                searchText.isEmpty
                    || recipe.title.localizedCaseInsensitiveContains(searchText)
                    || recipe.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
            .filter(recipeFilter.matches)
    }

    private var availableCuisines: [String] {
        Array(Set(recipes.compactMap(\.tags.first))).sorted()
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeCardView(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                recipePendingDelete = recipe
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(12)
            }
            .background(AppColor.background)
            .navigationTitle("Recipes")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .navigationDestination(for: TagFilter.self) { filter in
                TaggedRecipesView(tag: filter.tag)
            }
            .searchable(text: $searchText, prompt: "Search by title or tag")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingFilters = true
                    } label: {
                        Image(systemName: recipeFilter.isActive
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    GlobalAddMenu()
                }
            }
            .sheet(isPresented: $isPresentingFilters) {
                RecipeFilterView(filter: $recipeFilter, availableCuisines: availableCuisines)
            }
            .alert(
                "Delete Recipe?",
                isPresented: Binding(
                    get: { recipePendingDelete != nil },
                    set: { if !$0 { recipePendingDelete = nil } }
                )
            ) {
                Button("Delete", role: .destructive) {
                    if let recipe = recipePendingDelete { delete(recipe) }
                    recipePendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    recipePendingDelete = nil
                }
            } message: {
                Text("This can't be undone.")
            }
            .overlay {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "fork.knife",
                        description: Text("Tap + to add your first recipe.")
                    )
                } else if filteredRecipes.isEmpty {
                    ContentUnavailableView(
                        "No Matches",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Try adjusting or clearing your filters.")
                    )
                }
            }
        }
    }

    private func delete(_ recipe: Recipe) {
        for filename in recipe.photoFilenames {
            PhotoStore.delete(filename)
        }
        modelContext.delete(recipe)
    }
}

#Preview {
    RecipeListView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
