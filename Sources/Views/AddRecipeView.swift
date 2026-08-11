import PhotosUI
import SwiftData
import SwiftUI
import UIKit

private struct StepEntry: Identifiable, Hashable {
    let id = UUID()
    var text: String
}

struct AddRecipeView: View {
    private enum Field: Hashable {
        case prepTime, cookTime, servings, sourceURL
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var title = ""
    @State private var ingredientRows: [IngredientEntry] = [IngredientEntry()]
    @State private var steps: [StepEntry] = [StepEntry(text: "")]
    @State private var tagsText = ""
    @State private var prepTimeText = ""
    @State private var cookTimeText = ""
    @State private var servingsText = ""
    @State private var sourceURLText = ""

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Recipe title", text: $title)
                }
                Section("Photo") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Label("Add a cover photo", systemImage: "photo")
                        }
                    }
                    .onChange(of: selectedPhotoItem) {
                        Task {
                            selectedPhotoData = try? await selectedPhotoItem?.loadTransferable(type: Data.self)
                        }
                    }
                }
                Section("Ingredients") {
                    ForEach($ingredientRows) { $row in
                        HStack(spacing: 8) {
                            TextField("Amt", value: $row.amount, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 50)
                            TextField("Unit", text: $row.unit)
                                .frame(width: 60)
                            TextField("Ingredient", text: $row.name)
                                .onChange(of: row.name) { _, newValue in
                                    if row.unit.isEmpty, let suggestion = IngredientUnitSuggestions.suggestedUnit(for: newValue) {
                                        row.unit = suggestion
                                    }
                                }
                            if ingredientRows.count > 1 {
                                Button(role: .destructive) {
                                    ingredientRows.removeAll { $0.id == row.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    Button {
                        ingredientRows.append(IngredientEntry())
                    } label: {
                        Label("Add Ingredient", systemImage: "plus.circle")
                    }
                }
                Section("Instructions") {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, _ in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .frame(width: 20, alignment: .trailing)
                            TextField("Step \(index + 1)", text: $steps[index].text, axis: .vertical)
                                .lineLimit(1...4)
                            if steps.count > 1 {
                                Button(role: .destructive) {
                                    steps.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    Button {
                        steps.append(StepEntry(text: ""))
                    } label: {
                        Label("Add Step", systemImage: "plus.circle")
                    }
                }
                Section("Details") {
                    TextField("Prep time (minutes)", text: $prepTimeText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .prepTime)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .cookTime }
                    TextField("Cook time (minutes)", text: $cookTimeText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .cookTime)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .servings }
                    TextField("Servings", text: $servingsText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .servings)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .sourceURL }
                    TextField("Source URL", text: $sourceURLText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .sourceURL)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                }
                Section("Tags") {
                    TextField("Comma separated, e.g. dinner, pasta", text: $tagsText)
                }
            }
            .scrollDismissesKeyboard(.interactively)
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
        let ingredients = ingredientRows
            .map { entry -> IngredientEntry in
                var cleaned = entry
                cleaned.name = entry.name.trimmingCharacters(in: .whitespaces)
                cleaned.unit = entry.unit.trimmingCharacters(in: .whitespaces)
                return cleaned
            }
            .filter { !$0.name.isEmpty }

        let instructionSteps = steps
            .map { $0.text.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var photoFilenames: [String] = []
        if let selectedPhotoData, let filename = PhotoStore.save(selectedPhotoData) {
            photoFilenames.append(filename)
        }

        let sourceURL = sourceURLText.trimmingCharacters(in: .whitespaces)

        let recipe = Recipe(
            title: title.trimmingCharacters(in: .whitespaces),
            ingredients: ingredients,
            instructionSteps: instructionSteps,
            tags: tags,
            photoFilenames: photoFilenames,
            prepTimeMinutes: Int(prepTimeText),
            cookTimeMinutes: Int(cookTimeText),
            servings: Int(servingsText),
            sourceURL: sourceURL.isEmpty ? nil : sourceURL
        )
        modelContext.insert(recipe)
        dismiss()
    }
}

#Preview {
    AddRecipeView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
