import SwiftUI
import UIKit

/// A distinct navigation value so `LeaderboardView` can push its own detail view for
/// `Recipe` (this file) while still offering a separate way to reach the real
/// `RecipeDetailView` from within it, without the two destinations colliding on the
/// same `NavigationStack`.
struct RecipeDetailDestination: Hashable {
    let recipe: Recipe
}

/// What tapping a leaderboard entry should actually show: how many times the recipe
/// has been cooked, each individual cook's rating and photo, and a way to jump to the
/// full recipe — rather than going straight to the recipe itself.
struct RecipePerformanceView: View {
    let recipe: Recipe

    private var sortedEntries: [CookingLogEntry] {
        (recipe.cookingLogEntries ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(recipe.timesCooked)")
                            .font(.title2.bold())
                            .foregroundStyle(AppColor.ink)
                        Text("times cooked")
                            .font(.caption)
                            .foregroundStyle(AppColor.inkMuted)
                    }
                    if let average = recipe.averageRating {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.1f/10", average))
                                .font(.title2.bold())
                                .foregroundStyle(AppColor.gold)
                            Text("average rating")
                                .font(.caption)
                                .foregroundStyle(AppColor.inkMuted)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
                .listRowBackground(AppColor.surface)

                NavigationLink(value: RecipeDetailDestination(recipe: recipe)) {
                    Label("View Recipe", systemImage: "book")
                }
                .listRowBackground(AppColor.surface)
            }

            Section("Cook History") {
                if sortedEntries.isEmpty {
                    Text("No cooks logged yet.")
                        .font(.caption)
                        .foregroundStyle(AppColor.inkMuted)
                        .listRowBackground(AppColor.surface)
                } else {
                    ForEach(sortedEntries) { entry in
                        CookLogRow(entry: entry)
                            .listRowBackground(AppColor.surface)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.background)
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CookLogRow: View {
    let entry: CookingLogEntry

    private var photoImage: UIImage? {
        guard let filename = entry.photoFilename else { return nil }
        return UIImage(contentsOfFile: PhotoStore.url(for: filename).path)
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let photoImage {
                    Image(uiImage: photoImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RecipePlaceholderView(glyphSize: 20)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text("\(entry.rating)/10")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColor.ink)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(AppColor.gold, in: Capsule())
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(AppColor.inkMuted)
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(AppColor.inkMuted)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
