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
        return PhotoStore.image(for: filename)
    }

    /// Gold for #1 (matching the rating badge's own gold elsewhere), silver for #2,
    /// bronze for #3 — nil everywhere else, where rank is just a plain number.
    private var medalColor: Color? {
        switch rank {
        case 1: AppColor.gold
        case 2: AppColor.silver
        case 3: AppColor.bronze
        default: nil
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            rankBadge

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
                            .background(AppColor.forRating(average), in: Capsule())
                        Text("Cooked ×\(recipe.timesCooked)")
                            .font(.caption2)
                            .foregroundStyle(AppColor.inkMuted)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var rankBadge: some View {
        if let medalColor {
            Text("\(rank)")
                .font(.system(.subheadline, design: .serif).bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(medalColor, in: Circle())
        } else {
            Text("\(rank)")
                .font(.system(.subheadline, design: .serif).bold())
                .foregroundStyle(AppColor.inkMuted)
                .frame(width: 26, height: 26)
        }
    }
}
