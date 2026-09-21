import SwiftData
import SwiftUI

/// A single continuous, chronologically-ordered agenda — no more paging by day or week.
/// Opens scrolled to today; scrolling up reveals earlier days (loading further back as
/// the top of the loaded range comes into view), scrolling down reveals later ones the
/// same way, the way a calendar app's list view works. Days before today are shown as
/// muted grey boxes; today and upcoming days are bright with bold date text, so the
/// history/upcoming split reads clearly rather than as a single dimmed/not-dimmed toggle.
struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealPlanEntry.date) private var allEntries: [MealPlanEntry]

    @State private var weeksBefore = 6
    @State private var weeksAfter = 6
    @State private var editingEntry: MealPlanEntry?
    @State private var isPresentingSchedule = false
    @State private var scheduleDate = Date.now

    /// Guards against a runaway extend-on-appear loop: prepending days above an
    /// unmoved scroll position puts the new edge row exactly where the old one was,
    /// so it re-appears and re-triggers immediately. Blocking re-entry and only
    /// allowing one extension per `loadDebounce` breaks that cascade; the two caps
    /// below stop it for good even if something re-triggers faster than the debounce.
    @State private var isLoadingMore = false
    @State private var hasCenteredOnToday = false

    private static let loadChunkInWeeks = 8
    private static let loadDebounce: TimeInterval = 0.4
    private static let maxWeeksBeforeOrAfter = 104

    private var today: Date { Calendar.current.startOfDay(for: .now) }

    /// Every day currently loaded, oldest first — `weeksBefore`/`weeksAfter` weeks on
    /// either side of the calendar week containing today.
    private var days: [Date] {
        let calendar = Calendar.current
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today),
              let firstWeekStart = calendar.date(byAdding: .weekOfYear, value: -weeksBefore, to: thisWeek.start)
        else { return [] }

        let totalWeeks = weeksBefore + weeksAfter + 1
        return (0..<totalWeeks).flatMap { offset -> [Date] in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: firstWeekStart) else {
                return []
            }
            return CalendarWeek.days(containing: weekStart)
        }
    }

    private func entries(for day: Date) -> [MealPlanEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    private func isPast(_ day: Date) -> Bool {
        day < today
    }

    /// Muted grey for past days, bright surface for today/upcoming — a filled box, not
    /// just dimmed text, so the distinction reads clearly rather than looking washed out.
    private func rowBackground(for day: Date) -> Color {
        isPast(day) ? AppColor.surfaceAlt : AppColor.surface
    }

    /// Muted for the past, bold ink for what's still ahead, bold accent for today —
    /// three distinct tiers instead of one dimmed/not-dimmed toggle.
    private func headerTextColor(for day: Date) -> Color {
        if isPast(day) { return AppColor.inkMuted }
        if Calendar.current.isDateInToday(day) { return AppColor.accent }
        return AppColor.ink
    }

    private func headerFontWeight(for day: Date) -> Font.Weight {
        isPast(day) ? .regular : .bold
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
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
                                .listRowBackground(rowBackground(for: day))
                            } else {
                                ForEach(dayEntries) { entry in
                                    Button {
                                        editingEntry = entry
                                    } label: {
                                        MealPlanRow(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(rowBackground(for: day))
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
                            HStack {
                                Text(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                    .font(.subheadline.weight(headerFontWeight(for: day)))
                                    .foregroundStyle(headerTextColor(for: day))
                                if Calendar.current.isDateInToday(day) {
                                    Text("Today")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(AppColor.accent)
                                }
                                Spacer()
                            }
                        }
                        .id(day)
                        .onAppear { extendRangeIfNeeded(reaching: day) }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppColor.background)
                .navigationTitle("Meal Plan")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Today") {
                            scrollToToday(proxy)
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        GlobalAddMenu()
                    }
                }
                .sheet(item: $editingEntry) { entry in
                    MealPlanEntryFormView(existingEntry: entry)
                }
                .sheet(isPresented: $isPresentingSchedule) {
                    MealPlanEntryFormView(initialDate: scheduleDate)
                }
                .onAppear {
                    // The list needs a beat to lay out before `scrollTo` has anywhere
                    // to land — this is the standard workaround for that first-appear gap.
                    // Extension stays blocked until this fires, since the initial layout
                    // starts at the oldest loaded day (the vulnerable edge) before this
                    // moves the viewport away from it.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        scrollToToday(proxy, animated: false)
                        hasCenteredOnToday = true
                    }
                }
            }
        }
    }

    private func scrollToToday(_ proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation {
                proxy.scrollTo(today, anchor: .top)
            }
        } else {
            proxy.scrollTo(today, anchor: .top)
        }
    }

    /// Loads another chunk of weeks once the currently-loaded edge scrolls into view, in
    /// whichever direction it was reached. See the guard properties above for why the
    /// debounce and hard caps exist — this can otherwise cascade into a runaway loop.
    private func extendRangeIfNeeded(reaching day: Date) {
        guard hasCenteredOnToday, !isLoadingMore else { return }
        guard let first = days.first, let last = days.last else { return }

        if day == first, weeksBefore < Self.maxWeeksBeforeOrAfter {
            isLoadingMore = true
            weeksBefore += Self.loadChunkInWeeks
        } else if day == last, weeksAfter < Self.maxWeeksBeforeOrAfter {
            isLoadingMore = true
            weeksAfter += Self.loadChunkInWeeks
        } else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.loadDebounce) {
            isLoadingMore = false
        }
    }
}

#Preview {
    MealPlanView()
        .modelContainer(for: [Recipe.self, MealPlanEntry.self, CookingLogEntry.self], inMemory: true)
}
