import SwiftData
import SwiftUI

/// Searchable list to pick an existing recipe — used anywhere a flow needs to
/// reference a recipe that already exists rather than create a new one.
struct RecipePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Binding var selection: Recipe?
    @State private var searchText = ""

    private var filteredRecipes: [Recipe] {
        guard !searchText.isEmpty else { return recipes }
        return recipes.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filteredRecipes) { recipe in
                Button {
                    selection = recipe
                    dismiss()
                } label: {
                    HStack {
                        Text(recipe.title)
                            .foregroundStyle(AppColor.ink)
                        Spacer()
                        if recipe == selection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColor.accent)
                        }
                    }
                }
                .listRowBackground(AppColor.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .searchable(text: $searchText, prompt: "Search recipes")
            .navigationTitle("Choose a Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "fork.knife",
                        description: Text("Add a recipe first, then plan it.")
                    )
                }
            }
        }
    }
}
