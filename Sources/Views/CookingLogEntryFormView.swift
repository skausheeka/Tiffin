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
    @State private var rating: Double
    @State private var cookDuration: TimeInterval
    @State private var noteText: String
    @State private var isPresentingRecipePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?

    private var timeMinutes: Int { Int(cookDuration / 60) }

    init(preselectedRecipe: Recipe? = nil) {
        _selectedRecipe = State(initialValue: preselectedRecipe)
        _date = State(initialValue: .now)
        _rating = State(initialValue: 5)
        _cookDuration = State(initialValue: Self.defaultDuration(for: preselectedRecipe))
        _noteText = State(initialValue: "")
    }

    /// Pre-fills from the recipe's last logged cook so re-cooking something is a quick
    /// confirm-or-tweak, not a blank required field every time. First-ever cook starts at 0.
    private static func defaultDuration(for recipe: Recipe?) -> TimeInterval {
        guard let lastLoggedTimeMinutes = recipe?.lastLoggedTimeMinutes else { return 0 }
        return TimeInterval(lastLoggedTimeMinutes * 60)
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
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("How did it go?") {
                    VStack(spacing: 10) {
                        Text(String(format: "%.1f/10", rating))
                            .font(.title3.bold())
                            .foregroundStyle(AppColor.gold)
                        Slider(value: $rating, in: 1...10, step: 0.1)
                            .tint(AppColor.gold)
                    }
                    .padding(.vertical, 4)
                }
                Section("How long did it take?") {
                    CookDurationPicker(duration: $cookDuration)
                        .frame(height: 150)
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
                        .disabled(selectedRecipe == nil || cookDuration <= 0)
                }
            }
            .sheet(isPresented: $isPresentingRecipePicker) {
                RecipeLookupView(selection: $selectedRecipe)
            }
            .onChange(of: selectedRecipe) { _, newValue in
                cookDuration = Self.defaultDuration(for: newValue)
            }
        }
    }

    private func save() {
        guard let selectedRecipe, cookDuration > 0 else { return }
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

/// Wraps `UIDatePicker`'s countdown-timer wheel — the same Hours/Min picker iOS uses for
/// Alarm and Timer durations — so the unit is self-evident without a label.
private struct CookDurationPicker: UIViewRepresentable {
    @Binding var duration: TimeInterval

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        picker.preferredDatePickerStyle = .wheels
        picker.countDownDuration = duration
        picker.addTarget(
            context.coordinator,
            action: #selector(Coordinator.durationChanged(_:)),
            for: .valueChanged
        )
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        if uiView.countDownDuration != duration {
            uiView.countDownDuration = duration
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(duration: $duration)
    }

    final class Coordinator: NSObject {
        let duration: Binding<TimeInterval>

        init(duration: Binding<TimeInterval>) {
            self.duration = duration
        }

        @objc func durationChanged(_ sender: UIDatePicker) {
            duration.wrappedValue = sender.countDownDuration
        }
    }
}

#Preview {
    CookingLogEntryFormView()
        .modelContainer(for: [Recipe.self, MealPlanEntry.self, CookingLogEntry.self], inMemory: true)
}
