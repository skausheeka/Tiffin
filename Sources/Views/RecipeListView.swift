import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var isPresentingAddRecipe = false
    @State private var path = NavigationPath()

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var filteredRecipes: [Recipe] {
        guard !searchText.isEmpty else { return recipes }
        return recipes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeCardView(recipe: recipe) { tag in
                                path.append(TagFilter(tag: tag))
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(recipe)
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
                    Button(action: { isPresentingAddRecipe = true }) {
                        Label("Add Recipe", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddRecipe) {
                AddRecipeView()
            }
            .overlay {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "fork.knife",
                        description: Text("Tap + to add your first recipe.")
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
