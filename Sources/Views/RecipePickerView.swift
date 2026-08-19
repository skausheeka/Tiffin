import SwiftData
import SwiftUI

/// Searchable card grid to pick an existing recipe — used anywhere a flow needs to
/// reference a recipe that already exists rather than create a new one. Also offers
/// creating a brand new recipe on the spot, for when the one you want isn't saved yet.
struct RecipePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Binding var selection: Recipe?
    @State private var searchText = ""
    @State private var isPresentingAddRecipe = false

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var filteredRecipes: [Recipe] {
        guard !searchText.isEmpty else { return recipes }
        return recipes.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredRecipes) { recipe in
                        Button {
                            selection = recipe
                            dismiss()
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                RecipeCardView(recipe: recipe)
                                if recipe == selection {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(AppColor.accent)
                                        .background(Circle().fill(.white))
                                        .padding(8)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
            .background(AppColor.background)
            .searchable(text: $searchText, prompt: "Search recipes")
            .navigationTitle("Choose a Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddRecipe = true
                    } label: {
                        Label("New Recipe", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddRecipe) {
                AddRecipeView()
            }
            .overlay {
                if recipes.isEmpty {
                    ContentUnavailableView {
                        Label("No Recipes Yet", systemImage: "fork.knife")
                    } description: {
                        Text("Add a recipe first, then plan it.")
                    } actions: {
                        Button {
                            isPresentingAddRecipe = true
                        } label: {
                            Label("New Recipe", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if filteredRecipes.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
}
