import SwiftData
import SwiftUI

/// Logs a single cooking event for a recipe — a date, a required rating, and
/// an optional note. This is how a recipe's average rating actually gets set.
struct CookingLogEntryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRecipe: Recipe?
    @State private var date: Date
    @State private var rating: Int?
    @State private var noteText: String
    @State private var isPresentingRecipePicker = false

    init(preselectedRecipe: Recipe? = nil) {
        _selectedRecipe = State(initialValue: preselectedRecipe)
        _date = State(initialValue: .now)
        _rating = State(initialValue: nil)
        _noteText = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    Button {
                        isPresentingRecipePicker = true
                    } label: {
                        HStack {
                            Text(selectedRecipe?.title ?? "Choose a recipe")
                                .foregroundStyle(selectedRecipe == nil ? AppColor.inkMuted : AppColor.ink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppColor.inkMuted)
                        }
                    }
                }
                Section("When") {
                    DatePicker("Date & time", selection: $date)
                }
                Section("How did it go?") {
                    HStack {
                        Spacer()
                        StarRatingView(rating: rating, size: 30) { star in
                            rating = (rating == star) ? nil : star
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                Section("Notes") {
                    TextField("e.g. turned out dry, less time next time", text: $noteText, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle("Log a Cook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(selectedRecipe == nil || rating == nil)
                }
            }
            .sheet(isPresented: $isPresentingRecipePicker) {
                RecipePickerView(selection: $selectedRecipe)
            }
        }
    }

    private func save() {
        guard let selectedRecipe, let rating else { return }
        let note = noteText.trimmingCharacters(in: .whitespaces)

        let entry = CookingLogEntry(
            date: date,
            rating: rating,
            note: note.isEmpty ? nil : note,
            recipe: selectedRecipe
        )
        modelContext.insert(entry)
        dismiss()
    }
}

#Preview {
    CookingLogEntryFormView()
        .modelContainer(for: [Recipe.self, MealPlanEntry.self, CookingLogEntry.self], inMemory: true)
}
