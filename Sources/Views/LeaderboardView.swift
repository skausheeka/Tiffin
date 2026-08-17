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
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
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
                    LinearGradient(
                        colors: [AppColor.accentSoft, AppColor.tertiarySoft],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                HStack(spacing: 4) {
                    StarRatingView(
                        rating: recipe.averageRating.map { Int($0.rounded()) },
                        size: 10,
                        interactive: false
                    )
                    if let average = recipe.averageRating {
                        Text(String(format: "%.1f · Cooked ×%d", average, recipe.timesCooked))
                            .font(.caption2)
                            .foregroundStyle(AppColor.inkMuted)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}
