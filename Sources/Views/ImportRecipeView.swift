import PhotosUI
import SwiftUI
import UIKit

/// Lets the user import a recipe by pasting a URL/text or by photographing a recipe
/// (handwritten or printed). Either path lands on the same `ParsedRecipeDraft`, which
/// prefills `AddRecipeView` for review — nothing is saved until the user taps Save there.
struct ImportRecipeView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case paste = "Paste"
        case photo = "Photo"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .paste
    @State private var inputText = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var isPresentingCamera = false
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var draft: ParsedRecipeDraft?
    @State private var isPresentingReview = false

    private var canImport: Bool {
        switch mode {
        case .paste:
            return !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .photo:
            return capturedImage != nil
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Import from", selection: $mode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch mode {
                case .paste:
                    pasteSection
                case .photo:
                    photoSection
                }

                Spacer()
            }
            .padding(.top, 12)
            .background(AppColor.background)
            .navigationTitle("Import Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        Task { await runImport() }
                    }
                    .disabled(!canImport || isImporting)
                }
            }
            .overlay {
                if isImporting {
                    ZStack {
                        Color.black.opacity(0.15).ignoresSafeArea()
                        ProgressView("Reading recipe…")
                            .padding(20)
                            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .alert("Couldn't Import Recipe", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .fullScreenCover(isPresented: $isPresentingCamera) {
                CameraCaptureView(
                    onCapture: { image in
                        capturedImage = image
                        isPresentingCamera = false
                    },
                    onCancel: { isPresentingCamera = false }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $isPresentingReview, onDismiss: { dismiss() }) {
                AddRecipeView(prefill: draft)
            }
        }
    }

    private var pasteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paste a recipe URL or the full recipe text")
                .font(.subheadline)
                .foregroundStyle(AppColor.inkMuted)
                .padding(.horizontal)

            TextEditor(text: $inputText)
                .frame(minHeight: 260)
                .padding(8)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
        }
    }

    private var photoSection: some View {
        VStack(spacing: 16) {
            Group {
                if let capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RecipePlaceholderView(glyphSize: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(maxHeight: 320)
            .padding(.horizontal)

            HStack(spacing: 12) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        isPresentingCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    .buttonStyle(.borderedProminent)
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                }
                .buttonStyle(.bordered)
                .onChange(of: selectedPhotoItem) {
                    Task {
                        if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                            capturedImage = UIImage(data: data)
                        }
                    }
                }
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func runImport() async {
        isImporting = true
        defer { isImporting = false }

        do {
            let imported: ParsedRecipeDraft
            switch mode {
            case .paste:
                imported = try await RecipeImporter.importRecipe(from: inputText)
            case .photo:
                guard let capturedImage, let jpegData = capturedImage.jpegData(compressionQuality: 0.85) else {
                    throw RecipeImportError.emptyInput
                }
                imported = try await RecipeImporter.importRecipe(fromImageData: jpegData, mediaType: "image/jpeg")
            }
            draft = imported
            isPresentingReview = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ImportRecipeView()
}
