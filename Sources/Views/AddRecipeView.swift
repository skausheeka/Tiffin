import SwiftData
import SwiftUI

struct AddRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var ingredientsText = ""
    @State private var instructions = ""
    @State private var tagsText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Recipe title", text: $title)
                }
                Section("Ingredients") {
                    TextField("One per line", text: $ingredientsText, axis: .vertical)
                        .lineLimit(4...10)
                }
                Section("Instructions") {
                    TextField("Steps", text: $instructions, axis: .vertical)
                        .lineLimit(4...10)
                }
                Section("Tags") {
                    TextField("Comma separated, e.g. dinner, pasta", text: $tagsText)
                }
            }
            .navigationTitle("New Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let ingredients = ingredientsText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let recipe = Recipe(
            title: title.trimmingCharacters(in: .whitespaces),
            ingredients: ingredients,
            instructions: instructions,
            tags: tags
        )
        modelContext.insert(recipe)
        dismiss()
    }
}

#Preview {
    AddRecipeView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
