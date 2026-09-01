import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Logs a single cooking event for a recipe — a date, a required rating, and
/// an optional note. This is how a recipe's average rating actually gets set.
struct CookingLogEntryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRecipe: Recipe?
    @State private var date: Date
    @State private var rating: Int
    @State private var timeText: String
    @State private var noteText: String
    @State private var isPresentingRecipePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?

    private var timeMinutes: Int? { Int(timeText) }

    init(preselectedRecipe: Recipe? = nil) {
        _selectedRecipe = State(initialValue: preselectedRecipe)
        _date = State(initialValue: .now)
        _rating = State(initialValue: 5)
        _timeText = State(initialValue: "")
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
                    VStack(spacing: 10) {
                        Text("\(rating)/10")
                            .font(.title3.bold())
                            .foregroundStyle(AppColor.gold)
                        Slider(
                            value: Binding(
                                get: { Double(rating) },
                                set: { rating = Int($0.rounded()) }
                            ),
                            in: 1...10,
                            step: 1
                        )
                        .tint(AppColor.gold)
                    }
                    .padding(.vertical, 4)
                }
                Section("How long did it take?") {
                    TextField("Minutes", text: $timeText)
                        .keyboardType(.numberPad)
                }
                Section("Photo") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 160)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Label("Add a photo of how it turned out", systemImage: "camera")
                        }
                    }
                    .onChange(of: selectedPhotoItem) {
                        Task {
                            photoData = try? await selectedPhotoItem?.loadTransferable(type: Data.self)
                        }
                    }
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
                        .disabled(selectedRecipe == nil || timeMinutes == nil)
                }
            }
            .sheet(isPresented: $isPresentingRecipePicker) {
                RecipePickerView(selection: $selectedRecipe)
            }
        }
    }

    private func save() {
        guard let selectedRecipe, let timeMinutes else { return }
        let note = noteText.trimmingCharacters(in: .whitespaces)
        let photoFilename = photoData.flatMap { PhotoStore.save($0) }

        let entry = CookingLogEntry(
            date: date,
            rating: rating,
            timeMinutes: timeMinutes,
            note: note.isEmpty ? nil : note,
            photoFilename: photoFilename,
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
