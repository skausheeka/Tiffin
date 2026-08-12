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

    private let existingRecipe: Recipe?

    @State private var title: String
    @State private var ingredientRows: [IngredientEntry]
    @State private var steps: [StepEntry]
    @State private var tagsText: String
    @State private var prepTimeText: String
    @State private var cookTimeText: String
    @State private var servingsText: String
    @State private var sourceURLText: String
    @State private var noteText: String
    @State private var selectedCourse: RecipeCourse?

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var didChangePhoto = false

    init(existingRecipe: Recipe? = nil) {
        self.existingRecipe = existingRecipe
        _title = State(initialValue: existingRecipe?.title ?? "")
        _ingredientRows = State(initialValue: existingRecipe?.ingredients.isEmpty == false ? existingRecipe!.ingredients : [IngredientEntry()])
        let existingSteps = existingRecipe?.instructionSteps.map { StepEntry(text: $0) } ?? []
        _steps = State(initialValue: existingSteps.isEmpty ? [StepEntry(text: "")] : existingSteps)
        _tagsText = State(initialValue: existingRecipe?.tags.joined(separator: ", ") ?? "")
        _prepTimeText = State(initialValue: existingRecipe?.prepTimeMinutes.map(String.init) ?? "")
        _cookTimeText = State(initialValue: existingRecipe?.cookTimeMinutes.map(String.init) ?? "")
        _servingsText = State(initialValue: existingRecipe?.servings.map(String.init) ?? "")
        _sourceURLText = State(initialValue: existingRecipe?.sourceURL ?? "")
        _noteText = State(initialValue: existingRecipe?.note ?? "")
        _selectedCourse = State(initialValue: existingRecipe?.courseValue)

        if let filename = existingRecipe?.coverPhotoFilename,
           let data = try? Data(contentsOf: PhotoStore.url(for: filename)) {
            _selectedPhotoData = State(initialValue: data)
        } else {
            _selectedPhotoData = State(initialValue: nil)
        }
    }

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
                            didChangePhoto = true
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
                    Picker("Course", selection: $selectedCourse) {
                        Text("None").tag(RecipeCourse?.none)
                        ForEach(RecipeCourse.allCases) { course in
                            Text(course.rawValue).tag(RecipeCourse?.some(course))
                        }
                    }
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
                Section("Notes") {
                    TextField("e.g. add more salt next time", text: $noteText, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle(existingRecipe == nil ? "New Recipe" : "Edit Recipe")
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

        let sourceURL = sourceURLText.trimmingCharacters(in: .whitespaces)
        let note = noteText.trimmingCharacters(in: .whitespaces)

        if let existingRecipe {
            existingRecipe.title = title.trimmingCharacters(in: .whitespaces)
            existingRecipe.ingredients = ingredients
            existingRecipe.instructionSteps = instructionSteps
            existingRecipe.tags = tags
            existingRecipe.prepTimeMinutes = Int(prepTimeText)
            existingRecipe.cookTimeMinutes = Int(cookTimeText)
            existingRecipe.servings = Int(servingsText)
            existingRecipe.sourceURL = sourceURL.isEmpty ? nil : sourceURL
            existingRecipe.course = selectedCourse?.rawValue
            existingRecipe.note = note.isEmpty ? nil : note

            if didChangePhoto {
                for filename in existingRecipe.photoFilenames {
                    PhotoStore.delete(filename)
                }
                if let selectedPhotoData, let filename = PhotoStore.save(selectedPhotoData) {
                    existingRecipe.photoFilenames = [filename]
                } else {
                    existingRecipe.photoFilenames = []
                }
            }
        } else {
            var photoFilenames: [String] = []
            if let selectedPhotoData, let filename = PhotoStore.save(selectedPhotoData) {
                photoFilenames.append(filename)
            }

            let recipe = Recipe(
                title: title.trimmingCharacters(in: .whitespaces),
                ingredients: ingredients,
                instructionSteps: instructionSteps,
                tags: tags,
                photoFilenames: photoFilenames,
                prepTimeMinutes: Int(prepTimeText),
                cookTimeMinutes: Int(cookTimeText),
                servings: Int(servingsText),
                sourceURL: sourceURL.isEmpty ? nil : sourceURL,
                course: selectedCourse,
                note: note.isEmpty ? nil : note
            )
            modelContext.insert(recipe)
        }
        dismiss()
    }
}

#Preview {
    AddRecipeView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
