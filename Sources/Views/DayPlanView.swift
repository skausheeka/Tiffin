import SwiftData
import SwiftUI
import UIKit

struct DayPlanView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealPlanEntry.date) private var allEntries: [MealPlanEntry]
    @State private var editingEntry: MealPlanEntry?
    @State private var isPresentingSchedule = false
    @State private var isPresentingLogCook = false

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
                ContentUnavailableView {
                    Label("Nothing Planned", systemImage: "calendar")
                } description: {
                    Text("Add a meal for this day, or log one you already made.")
                } actions: {
                    Button {
                        isPresentingSchedule = true
                    } label: {
                        Label("Schedule a Meal", systemImage: "calendar.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        isPresentingLogCook = true
                    } label: {
                        Label("Log a Cook", systemImage: "star")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .sheet(item: $editingEntry) { entry in
            MealPlanEntryFormView(existingEntry: entry)
        }
        .sheet(isPresented: $isPresentingSchedule) {
            MealPlanEntryFormView(initialDate: date)
        }
        .sheet(isPresented: $isPresentingLogCook) {
            CookingLogEntryFormView()
        }
    }
}
