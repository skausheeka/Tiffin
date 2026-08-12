import SwiftData
import SwiftUI

struct MealPlanEntryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let existingEntry: MealPlanEntry?

    @State private var selectedRecipe: Recipe?
    @State private var date: Date
    @State private var servings: Int
    @State private var expectsLeftovers: Bool
    @State private var isPresentingRecipePicker = false

    init(existingEntry: MealPlanEntry? = nil, initialDate: Date = .now, preselectedRecipe: Recipe? = nil) {
        self.existingEntry = existingEntry
        let recipe = existingEntry?.recipe ?? preselectedRecipe
        _selectedRecipe = State(initialValue: recipe)
        _date = State(initialValue: existingEntry?.date ?? initialDate)
        _servings = State(initialValue: existingEntry?.servings ?? recipe?.servings ?? 1)
        _expectsLeftovers = State(initialValue: existingEntry?.expectsLeftovers ?? false)
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
                Section("Details") {
                    Stepper("Servings: \(servings)", value: $servings, in: 1...50)
                    Toggle("Expect leftovers?", isOn: $expectsLeftovers)
                }
                if existingEntry != nil {
                    Section {
                        Button("Remove from Meal Plan", role: .destructive, action: delete)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle(existingEntry == nil ? "Add to Meal Plan" : "Edit Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(selectedRecipe == nil)
                }
            }
            .sheet(isPresented: $isPresentingRecipePicker) {
                RecipePickerView(selection: $selectedRecipe)
            }
        }
    }

    private func save() {
        guard let selectedRecipe else { return }
        if let existingEntry {
            existingEntry.recipe = selectedRecipe
            existingEntry.date = date
            existingEntry.servings = servings
            existingEntry.expectsLeftovers = expectsLeftovers
        } else {
            let entry = MealPlanEntry(
                date: date,
                recipe: selectedRecipe,
                servings: servings,
                expectsLeftovers: expectsLeftovers
            )
            modelContext.insert(entry)
        }
        dismiss()
    }

    private func delete() {
        if let existingEntry {
            modelContext.delete(existingEntry)
        }
        dismiss()
    }
}

private struct RecipePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Binding var selection: Recipe?
    @State private var searchText = ""

    private var filteredRecipes: [Recipe] {
        guard !searchText.isEmpty else { return recipes }
        return recipes.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filteredRecipes) { recipe in
                Button {
                    selection = recipe
                    dismiss()
                } label: {
                    HStack {
                        Text(recipe.title)
                            .foregroundStyle(AppColor.ink)
                        Spacer()
                        if recipe == selection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColor.accent)
                        }
                    }
                }
                .listRowBackground(AppColor.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .searchable(text: $searchText, prompt: "Search recipes")
            .navigationTitle("Choose a Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "fork.knife",
                        description: Text("Add a recipe first, then plan it.")
                    )
                }
            }
        }
    }
}
