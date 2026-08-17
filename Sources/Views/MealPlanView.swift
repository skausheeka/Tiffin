import SwiftUI

struct MealPlanView: View {
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var isPresentingAdd = false

    private var dateLabel: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        }
        return selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        shiftDay(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(dateLabel)
                            .font(.headline)
                            .foregroundStyle(AppColor.ink)
                        if !Calendar.current.isDateInToday(selectedDate) {
                            Button("Today") {
                                selectedDate = Calendar.current.startOfDay(for: .now)
                            }
                            .font(.caption)
                        }
                    }

                    Spacer()

                    Button {
                        shiftDay(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundStyle(AppColor.accent)
                .padding(.horizontal)
                .padding(.vertical, 10)

                DayPlanView(date: selectedDate)
            }
            .background(AppColor.background)
            .navigationTitle("Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Label("Add Meal", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                MealPlanEntryFormView(initialDate: selectedDate)
            }
        }
    }

    private func shiftDay(by amount: Int) {
        selectedDate = Calendar.current.date(byAdding: .day, value: amount, to: selectedDate) ?? selectedDate
    }
}

#Preview {
    MealPlanView()
        .modelContainer(for: [Recipe.self, MealPlanEntry.self, CookingLogEntry.self], inMemory: true)
}
