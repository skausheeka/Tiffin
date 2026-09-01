import SwiftData
import SwiftUI
import UIKit

/// Fast, search-first recipe lookup — for flows where you already know exactly which
/// recipe you want (like logging a cook right after making it) rather than browsing to
/// decide. A plain list that narrows as you type, not a card grid to scan through.
struct RecipeLookupView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Binding var selection: Recipe?
    @State private var searchText = ""
    @State private var isPresentingAddRecipe = false

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
                    RecipeLookupRow(recipe: recipe, isSelected: recipe == selection)
                }
                .buttonStyle(.plain)
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
                        Text("Add a recipe first, then log a cook.")
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

private struct RecipeLookupRow: View {
    let recipe: Recipe
    let isSelected: Bool

    private var coverImage: UIImage? {
        guard let filename = recipe.coverPhotoFilename else { return nil }
        return UIImage(contentsOfFile: PhotoStore.url(for: filename).path)
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(AppColor.forCourse(recipe.courseValue))
                .frame(width: 4)

            Group {
                if let coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RecipePlaceholderView(glyphSize: 22)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                if let course = recipe.courseValue {
                    Text(course.rawValue)
                        .font(.caption)
                        .foregroundStyle(AppColor.inkMuted)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColor.accent)
            }
        }
        .padding(.vertical, 4)
    }
}
