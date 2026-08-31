import SwiftData
import SwiftUI
import UIKit

struct LeaderboardView: View {
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]

    private var rankedRecipes: [Recipe] {
        Recipe.ranked(allRecipes)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(rankedRecipes.enumerated()), id: \.element.id) { index, recipe in
                    NavigationLink(value: recipe) {
                        LeaderboardRow(rank: index + 1, recipe: recipe)
                    }
                    .listRowBackground(AppColor.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle("Leaderboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    GlobalAddMenu()
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipePerformanceView(recipe: recipe)
            }
            .navigationDestination(for: RecipeDetailDestination.self) { destination in
                RecipeDetailView(recipe: destination.recipe)
            }
            .overlay {
                if rankedRecipes.isEmpty {
                    ContentUnavailableView(
                        "No Ratings Yet",
                        systemImage: "star",
                        description: Text("Rate a recipe from its detail page to see it here.")
                    )
                }
            }
        }
    }
}

private struct LeaderboardRow: View {
    let rank: Int
    let recipe: Recipe

    private var coverImage: UIImage? {
        guard let filename = recipe.coverPhotoFilename else { return nil }
        return UIImage(contentsOfFile: PhotoStore.url(for: filename).path)
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.system(.subheadline, design: .serif).bold())
                .foregroundStyle(AppColor.inkMuted)
                .frame(width: 20)

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
                if let average = recipe.averageRating {
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", average))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppColor.ink)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColor.gold, in: Capsule())
                        Text("Cooked ×\(recipe.timesCooked)")
                            .font(.caption2)
                            .foregroundStyle(AppColor.inkMuted)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}
