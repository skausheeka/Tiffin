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

    private enum ValidationIssue: Hashable {
        case title, ingredients, steps
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var validationIssues: Set<ValidationIssue> = []

    private let existingRecipe: Recipe?
    private let isImportedPrefill: Bool

    @State private var title: String
    @State private var ingredientRows: [IngredientEntry]
    @State private var steps: [StepEntry]
    @State private var tags: [String]
    @State private var newTagText = ""
    @State private var prepTimeText: String
    @State private var cookTimeText: String
    @State private var servingsText: String
    @State private var sourceURLText: String
    @State private var noteText: String
    @State private var selectedCourse: RecipeCourse?

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var photoDatas: [Data] = []
    @State private var didChangePhotos = false
    @State private var customUnitRowIDs: Set<UUID> = []

    init(existingRecipe: Recipe? = nil, prefill: ParsedRecipeDraft? = nil) {
        self.existingRecipe = existingRecipe
        self.isImportedPrefill = existingRecipe == nil && prefill != nil
        _title = State(initialValue: existingRecipe?.title ?? prefill?.title ?? "")
        let ingredientSource = existingRecipe?.ingredients ?? prefill?.ingredients ?? []
        _ingredientRows = State(initialValue: ingredientSource.isEmpty ? [IngredientEntry()] : ingredientSource)
        let stepsSource = existingRecipe?.instructionSteps ?? prefill?.steps ?? []
        let existingSteps = stepsSource.map { StepEntry(text: $0) }
        _steps = State(initialValue: existingSteps.isEmpty ? [StepEntry(text: "")] : existingSteps)
        _tags = State(initialValue: existingRecipe?.tags ?? prefill?.tags ?? [])
        _prepTimeText = State(initialValue: (existingRecipe?.prepTimeMinutes ?? prefill?.prepTimeMinutes).map(String.init) ?? "")
        _cookTimeText = State(initialValue: (existingRecipe?.cookTimeMinutes ?? prefill?.cookTimeMinutes).map(String.init) ?? "")
        _servingsText = State(initialValue: (existingRecipe?.servings ?? prefill?.servings).map(String.init) ?? "")
        _sourceURLText = State(initialValue: existingRecipe?.sourceURL ?? prefill?.sourceURL ?? "")
        _noteText = State(initialValue: existingRecipe?.note ?? "")
        _selectedCourse = State(initialValue: existingRecipe?.courseValue ?? prefill?.course)

        let existingPhotoDatas = (existingRecipe?.photoFilenames ?? []).compactMap { filename in
            try? Data(contentsOf: PhotoStore.url(for: filename))
        }
        _photoDatas = State(initialValue: existingPhotoDatas)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Recipe title", text: $title)
                        .onChange(of: title) { _, newValue in
                            if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                validationIssues.remove(.title)
                            }
                        }
                    if validationIssues.contains(.title) {
                        validationMessage("Title is required")
                    }
                }
                Section("Photos") {
                    if !photoDatas.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(photoDatas.enumerated()), id: \.offset) { index, data in
                                    ZStack(alignment: .topTrailing) {
                                        if let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        Button {
                                            photoDatas.remove(at: index)
                                            didChangePhotos = true
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(.white, .black.opacity(0.6))
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    PhotosPicker(selection: $selectedPhotoItems, matching: .images) {
                        Label(photoDatas.isEmpty ? "Add photos" : "Add more photos", systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: selectedPhotoItems) {
                        Task {
                            for item in selectedPhotoItems {
                                if let data = try? await item.loadTransferable(type: Data.self) {
                                    photoDatas.append(data)
                                }
                            }
                            selectedPhotoItems = []
                            didChangePhotos = true
                        }
                    }
                }
                Section("Ingredients") {
                    ForEach($ingredientRows) { $row in
                        HStack(spacing: 8) {
                            TextField("Amt", value: $row.amount, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 50)

                            if customUnitRowIDs.contains(row.id) {
                                TextField("Unit", text: $row.unit)
                                    .frame(width: 70)
                                    .onChange(of: row.unit) { _, newValue in
                                        if newValue.isEmpty {
                                            customUnitRowIDs.remove(row.id)
                                        }
                                    }
                            } else {
                                Menu {
                                    ForEach(IngredientUnitSuggestions.allUnits, id: \.self) { unit in
                                        Button(unit) { row.unit = unit }
                                    }
                                    Divider()
                                    Button("Other…") {
                                        row.unit = ""
                                        customUnitRowIDs.insert(row.id)
                                    }
                                } label: {
                                    Text(row.unit.isEmpty ? "Unit" : row.unit)
                                        .foregroundStyle(row.unit.isEmpty ? AppColor.inkMuted : AppColor.ink)
                                        .frame(width: 70, alignment: .leading)
                                }
                            }

                            TextField("Ingredient", text: $row.name)
                                .onChange(of: row.name) { _, newValue in
                                    if row.unit.isEmpty, let suggestion = IngredientUnitSuggestions.suggestedUnit(for: newValue) {
                                        row.unit = suggestion
                                    }
                                }
                            if ingredientRows.count > 1 {
                                Button(role: .destructive) {
                                    ingredientRows.removeAll { $0.id == row.id }
                                    customUnitRowIDs.remove(row.id)
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
                    if validationIssues.contains(.ingredients) {
                        validationMessage("Add at least one ingredient")
                    }
                }
                .onChange(of: ingredientRows) { _, newValue in
                    if validationIssues.contains(.ingredients), !Recipe.cleanIngredients(newValue).isEmpty {
                        validationIssues.remove(.ingredients)
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
                    if validationIssues.contains(.steps) {
                        validationMessage("Add at least one instruction step")
                    }
                }
                .onChange(of: steps) { _, newValue in
                    if validationIssues.contains(.steps), !Recipe.cleanSteps(newValue.map(\.text)).isEmpty {
                        validationIssues.remove(.steps)
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
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(AppColor.inkMuted)
                                .frame(width: 5, height: 5)
                            Text(tag)
                            Spacer()
                            Button(role: .destructive) {
                                tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    TextField("Add a tag, e.g. dinner", text: $newTagText)
                        .submitLabel(.done)
                        .onSubmit(commitTag)
                }
                Section("Notes") {
                    TextField("e.g. add more salt next time", text: $noteText, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle(existingRecipe != nil ? "Edit Recipe" : (isImportedPrefill ? "Review Imported Recipe" : "New Recipe"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
        }
    }

    @ViewBuilder
    private func validationMessage(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.circle.fill")
            .font(.caption)
            .foregroundStyle(.red)
    }

    private func commitTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespaces)
        newTagText = ""
        guard !trimmed.isEmpty, !tags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        tags.append(trimmed)
    }

    private func save() {
        commitTag()

        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let ingredients = Recipe.cleanIngredients(ingredientRows)
        let instructionSteps = Recipe.cleanSteps(steps.map(\.text))

        var issues: Set<ValidationIssue> = []
        if trimmedTitle.isEmpty { issues.insert(.title) }
        if ingredients.isEmpty { issues.insert(.ingredients) }
        if instructionSteps.isEmpty { issues.insert(.steps) }

        guard issues.isEmpty else {
            validationIssues = issues
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        let sourceURL = sourceURLText.trimmingCharacters(in: .whitespaces)
        let note = noteText.trimmingCharacters(in: .whitespaces)

        if let existingRecipe {
            existingRecipe.title = trimmedTitle
            existingRecipe.ingredients = ingredients
            existingRecipe.instructionSteps = instructionSteps
            existingRecipe.tags = tags
            existingRecipe.prepTimeMinutes = Int(prepTimeText)
            existingRecipe.cookTimeMinutes = Int(cookTimeText)
            existingRecipe.servings = Int(servingsText)
            existingRecipe.sourceURL = sourceURL.isEmpty ? nil : sourceURL
            existingRecipe.course = selectedCourse?.rawValue
            existingRecipe.note = note.isEmpty ? nil : note

            if didChangePhotos {
                for filename in existingRecipe.photoFilenames {
                    PhotoStore.delete(filename)
                }
                existingRecipe.photoFilenames = photoDatas.compactMap { PhotoStore.save($0) }
            }
        } else {
            let photoFilenames = photoDatas.compactMap { PhotoStore.save($0) }

            let recipe = Recipe(
                title: trimmedTitle,
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
