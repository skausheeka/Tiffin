import SwiftData
import SwiftUI
import UIKit

struct RecipeDetailView: View {
    let recipe: Recipe

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isPresentingEdit = false
    @State private var isPresentingMealPlanAdd = false
    @State private var isPresentingLogCook = false
    @State private var isPresentingDeleteConfirmation = false

    private var coverImage: UIImage? {
        guard let filename = recipe.coverPhotoFilename else { return nil }
        return UIImage(contentsOfFile: PhotoStore.url(for: filename).path)
    }

    private var metaLine: String? {
        var parts: [String] = []
        if let prep = recipe.prepTimeMinutes { parts.append("Prep \(prep) min") }
        if let cook = recipe.cookTimeMinutes { parts.append("Cook \(cook) min") }
        if let servings = recipe.servings { parts.append("Serves \(servings)") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let course = recipe.courseValue {
                    Text(course.rawValue)
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.4)
                        .foregroundStyle(AppColor.accent)
                }

                if !recipe.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(recipe.tags, id: \.self) { tag in
                                NavigationLink(value: TagFilter(tag: tag)) {
                                    Text(tag)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(AppColor.ink)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(AppColor.accentSoft, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if let metaLine {
                    Text(metaLine)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.inkMuted)
                }

                HStack(spacing: 12) {
                    if let average = recipe.averageRating {
                        HStack(spacing: 6) {
                            StarRatingView(rating: Int(average.rounded()), size: 18, interactive: false)
                            Text(String(format: "%.1f · Cooked ×%d", average, recipe.timesCooked))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColor.inkMuted)
                        }
                    } else {
                        Text("Not cooked yet")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColor.inkMuted)
                    }

                    Button {
                        isPresentingLogCook = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Log a Cook")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColor.secondarySoft, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if let note = recipe.note, !note.isEmpty {
                    Text("\u{201C}\(note)\u{201D}")
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(AppColor.inkMuted)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.surfaceAlt, in: RoundedRectangle(cornerRadius: 12))
                }

                if !recipe.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ingredients").font(.title3.bold()).foregroundStyle(AppColor.ink)
                        ForEach(recipe.ingredients) { ingredient in
                            Text("• \(ingredientLine(ingredient))")
                                .foregroundStyle(AppColor.ink)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.surfaceAlt, in: RoundedRectangle(cornerRadius: 14))
                }

                if !recipe.instructionSteps.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Instructions").font(.title3.bold()).foregroundStyle(AppColor.ink)
                        ForEach(Array(recipe.instructionSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppColor.surface)
                                    .frame(width: 20, height: 20)
                                    .background(AppColor.secondary, in: Circle())
                                Text(step)
                                    .foregroundStyle(AppColor.ink)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.surfaceAlt, in: RoundedRectangle(cornerRadius: 14))
                }

                if let sourceURLString = recipe.sourceURL, let url = URL(string: sourceURLString) {
                    Link(destination: url) {
                        Label("View source", systemImage: "link")
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppColor.accent)
                }
            }
            .padding()
        }
        .background(AppColor.background)
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingMealPlanAdd = true
                } label: {
                    Label("Add to Meal Plan", systemImage: "calendar.badge.plus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isPresentingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        isPresentingDeleteConfirmation = true
                    } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isPresentingEdit) {
            AddRecipeView(existingRecipe: recipe)
        }
        .sheet(isPresented: $isPresentingMealPlanAdd) {
            MealPlanEntryFormView(preselectedRecipe: recipe)
        }
        .sheet(isPresented: $isPresentingLogCook) {
            CookingLogEntryFormView(preselectedRecipe: recipe)
        }
        .alert("Delete Recipe?", isPresented: $isPresentingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: deleteRecipe)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    private func deleteRecipe() {
        for filename in recipe.photoFilenames {
            PhotoStore.delete(filename)
        }
        modelContext.delete(recipe)
        dismiss()
    }

    private func ingredientLine(_ ingredient: IngredientEntry) -> String {
        var parts: [String] = []
        if let amount = ingredient.amount {
            parts.append(amount.formatted(.number.precision(.fractionLength(0...2))))
        }
        if !ingredient.unit.isEmpty {
            parts.append(ingredient.unit)
        }
        parts.append(ingredient.name)
        return parts.joined(separator: " ")
    }
}
