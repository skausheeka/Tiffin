import SwiftUI

struct MealPlanView: View {
    private enum PlanMode: String, CaseIterable {
        case day = "Day", week = "Week"
    }

    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var mode: PlanMode = .day

    /// True when the visible period contains today — the default starting point for
    /// both modes. Day mode checks `selectedDate` directly; Week mode checks whether
    /// `selectedDate` falls in the same calendar week as today, since the week shown is
    /// always the Sunday–Saturday range containing `selectedDate`.
    private var isViewingCurrentPeriod: Bool {
        switch mode {
        case .day:
            return Calendar.current.isDateInToday(selectedDate)
        case .week:
            return Calendar.current.isDate(selectedDate, equalTo: .now, toGranularity: .weekOfYear)
        }
    }

    private var dateLabel: String {
        switch mode {
        case .day:
            if isViewingCurrentPeriod {
                return "Today, \(selectedDate.formatted(.dateTime.month(.abbreviated).day()))"
            }
            return selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        case .week:
            guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate),
                  let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: interval.end) else {
                return "This Week"
            }
            let range = "\(interval.start.formatted(.dateTime.month(.abbreviated).day())) – \(lastDay.formatted(.dateTime.month(.abbreviated).day()))"
            if isViewingCurrentPeriod {
                return "This Week, \(range)"
            }
            return range
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $mode) {
                    ForEach(PlanMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                HStack {
                    Button {
                        shift(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(dateLabel)
                        .font(.headline)
                        .foregroundStyle(AppColor.ink)

                    Spacer()

                    Button {
                        shift(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundStyle(AppColor.accent)
                .padding(.horizontal)
                .padding(.vertical, 10)

                if mode == .day {
                    DayPlanView(date: selectedDate)
                } else {
                    WeekPlanView(referenceDate: selectedDate) { day in
                        selectedDate = day
                        mode = .day
                    }
                }
            }
            .background(AppColor.background)
            .navigationTitle("Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Today") {
                        selectedDate = Calendar.current.startOfDay(for: .now)
                    }
                    .disabled(isViewingCurrentPeriod)
                }
                ToolbarItem(placement: .primaryAction) {
                    GlobalAddMenu()
                }
            }
        }
    }

    private func shift(by amount: Int) {
        switch mode {
        case .day:
            selectedDate = Calendar.current.date(byAdding: .day, value: amount, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: amount, to: selectedDate) ?? selectedDate
        }
    }
}

#Preview {
    MealPlanView()
        .modelContainer(for: [Recipe.self, MealPlanEntry.self, CookingLogEntry.self], inMemory: true)
}
