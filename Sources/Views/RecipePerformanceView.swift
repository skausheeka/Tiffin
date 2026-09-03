import Charts
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

            if sortedEntries.count >= 2 {
                Section("Last 5 Cooks") {
                    RatingTrendChart(entries: Array(sortedEntries.prefix(5).reversed()))
                        .listRowBackground(AppColor.surface)
                }

                if sortedEntries.count > 5 {
                    Section("Lifetime") {
                        RatingTrendChart(entries: Array(sortedEntries.reversed()))
                            .listRowBackground(AppColor.surface)
                    }
                }
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

/// A rating-over-time line, oldest cook on the left so an upward or downward trend
/// reads left-to-right. `entries` must already be in chronological (ascending) order.
/// Cooks sit at equally-spaced positions (not proportional to real elapsed time) —
/// how long ago something was cooked isn't the point, only the rating trend is.
private struct RatingTrendChart: View {
    let entries: [CookingLogEntry]

    private struct Point: Identifiable {
        let id: Int
        let index: Double
        let date: Date
        let rating: Double
    }

    /// How many points show at once before the chart scrolls. Every point still gets
    /// this much room, so its date label always has space and never gets truncated.
    private static let visiblePointCount = 5

    /// Margin reserved on each side of the plotted range and of the visible window, so
    /// a point sitting right at the edge never has its dot half-clipped by the plot bounds.
    private static let edgePadding: Double = 0.5

    /// Which unit the visible window starts at. Defaults to the tail end (minus the
    /// edge margin) so the most recent cook is on screen right away, dot included.
    @State private var scrollPosition: Double

    init(entries: [CookingLogEntry]) {
        self.entries = entries
        let count = entries.count
        _scrollPosition = State(
            initialValue: Double(max(count - Self.visiblePointCount, 0)) - Self.edgePadding
        )
    }

    private var points: [Point] {
        entries.enumerated().map { offset, entry in
            Point(id: offset, index: Double(offset), date: entry.date, rating: entry.rating)
        }
    }

    private var visibleLength: Double {
        Double(min(max(points.count, 1), Self.visiblePointCount))
    }

    private var fullDomain: ClosedRange<Double> {
        let maxIndex = Double(max(points.count - 1, 0))
        return -Self.edgePadding...(maxIndex + Self.edgePadding)
    }

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Cook", point.index),
                y: .value("Rating", point.rating)
            )
            .foregroundStyle(AppColor.accent)
            .interpolationMethod(.catmullRom)
            .symbol {
                Circle()
                    .fill(AppColor.accent)
                    .frame(width: 8, height: 8)
            }
        }
        .chartYScale(domain: -Self.edgePadding...(10 + Self.edgePadding))
        .chartXScale(domain: fullDomain)
        .chartXAxis {
            AxisMarks(values: points.map(\.index)) { value in
                AxisGridLine()
                AxisTick()
                if let raw = value.as(Double.self) {
                    let index = Int(raw.rounded())
                    if points.indices.contains(index) {
                        AxisValueLabel(Self.axisLabel(for: points[index].date))
                    }
                }
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: visibleLength)
        .chartScrollPosition(x: $scrollPosition)
        .frame(height: 130)
        .padding(.vertical, 4)
    }

    /// "Sep 2" for a date in the current year, "Jan 2025" for anything older — so a
    /// recipe that took a long time to recreate still reads clearly on the axis.
    private static func axisLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.component(.year, from: date) == calendar.component(.year, from: .now) {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
        return date.formatted(.dateTime.month(.abbreviated).year())
    }
}

private struct CookLogRow: View {
    let entry: CookingLogEntry

    private var photoImage: UIImage? {
        guard let filename = entry.photoFilename else { return nil }
        return PhotoStore.image(for: filename)
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
                Text(String(format: "%.1f/10", entry.rating))
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
