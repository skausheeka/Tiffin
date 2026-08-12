import SwiftData
import SwiftUI

struct TagFilter: Hashable {
    let tag: String
}

struct TaggedRecipesView: View {
    let tag: String

    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]

    private var recipes: [Recipe] {
        allRecipes.filter { $0.tags.contains { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame } }
    }

    var body: some View {
        List {
            ForEach(recipes) { recipe in
                NavigationLink(value: recipe) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(recipe.title)
                            .font(.headline)
                            .foregroundStyle(AppColor.ink)
                        if let course = recipe.courseValue {
                            Text(course.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColor.accent)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(AppColor.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.background)
        .navigationTitle(tag)
        .overlay {
            if recipes.isEmpty {
                ContentUnavailableView(
                    "No \(tag) Recipes",
                    systemImage: "fork.knife",
                    description: Text("Recipes tagged \"\(tag)\" will show up here.")
                )
            }
        }
    }
}
