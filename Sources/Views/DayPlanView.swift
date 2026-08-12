import SwiftData
import SwiftUI
import UIKit

struct DayPlanView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealPlanEntry.date) private var allEntries: [MealPlanEntry]
    @State private var editingEntry: MealPlanEntry?

    private var entries: [MealPlanEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        List {
            ForEach(entries) { entry in
                Button {
                    editingEntry = entry
                } label: {
                    MealPlanRow(entry: entry)
                }
                .buttonStyle(.plain)
                .listRowBackground(AppColor.surface)
                .swipeActions {
                    Button(role: .destructive) {
                        modelContext.delete(entry)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.background)
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    "Nothing Planned",
                    systemImage: "calendar",
                    description: Text("Tap + to add a meal for this day.")
                )
            }
        }
        .sheet(item: $editingEntry) { entry in
            MealPlanEntryFormView(existingEntry: entry)
        }
    }
}

private struct MealPlanRow: View {
    let entry: MealPlanEntry

    private var coverImage: UIImage? {
        guard let filename = entry.recipe?.coverPhotoFilename else { return nil }
        return UIImage(contentsOfFile: PhotoStore.url(for: filename).path)
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(AppColor.forCourse(entry.recipe?.courseValue))
                .frame(width: 4)

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
                Text(entry.recipe?.title ?? "Recipe")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                HStack(spacing: 6) {
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                    if let servings = entry.servings {
                        Text("· \(servings) servings")
                    }
                    if entry.expectsLeftovers {
                        Image(systemName: "takeoutbag.and.cup.and.straw")
                    }
                }
                .font(.caption)
                .foregroundStyle(AppColor.inkMuted)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
