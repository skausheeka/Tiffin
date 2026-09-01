import SwiftData
import SwiftUI

/// Read-only browsing surface for a whole week — one section per day showing what's
/// actually planned (reusing `MealPlanRow`), not just that something exists. Tapping a
/// day's header hands the date back to the caller to switch into the single-day view.
/// Always a calendar-aligned Sunday–Saturday week; which week is shown is controlled by
/// `referenceDate` (the caller can page to any past or future week). Days before today
/// are dimmed to distinguish history from what's still upcoming, but stay fully
/// interactive — past entries can still be edited, moved, or deleted.
struct WeekPlanView: View {
    let referenceDate: Date
    var onSelectDay: (Date) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealPlanEntry.date) private var allEntries: [MealPlanEntry]
    @State private var editingEntry: MealPlanEntry?
    @State private var isPresentingSchedule = false
    @State private var scheduleDate = Date.now

    private var days: [Date] {
        CalendarWeek.days(containing: referenceDate)
    }

    private func entries(for day: Date) -> [MealPlanEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    private func isPast(_ day: Date) -> Bool {
        day < Calendar.current.startOfDay(for: .now)
    }

    var body: some View {
        List {
            ForEach(days, id: \.self) { day in
                Section {
                    let dayEntries = entries(for: day)
                    if dayEntries.isEmpty {
                        Button {
                            scheduleDate = day
                            isPresentingSchedule = true
                        } label: {
                            HStack {
                                Text("Nothing planned")
                                    .foregroundStyle(AppColor.inkMuted)
                                Spacer()
                                Label("Add", systemImage: "plus.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(AppColor.accent)
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppColor.surface)
                    } else {
                        ForEach(dayEntries) { entry in
                            Button {
                                editingEntry = entry
                            } label: {
                                MealPlanRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(AppColor.surface)
                            .swipeActions {
                                Button(role: .destructive) {
                                    CookLogReminderScheduler.cancel(for: entry)
                                    modelContext.delete(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Button {
                        onSelectDay(day)
                    } label: {
                        HStack {
                            Text(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            if Calendar.current.isDateInToday(day) {
                                Text("Today")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(AppColor.accent)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .opacity(isPast(day) ? 0.55 : 1)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.background)
        .sheet(item: $editingEntry) { entry in
            MealPlanEntryFormView(existingEntry: entry)
        }
        .sheet(isPresented: $isPresentingSchedule) {
            MealPlanEntryFormView(initialDate: scheduleDate)
        }
    }
}
