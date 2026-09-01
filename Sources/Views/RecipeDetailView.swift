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

    private var images: [UIImage] {
        recipe.photoFilenames.compactMap { UIImage(contentsOfFile: PhotoStore.url(for: $0).path) }
    }

    private var heroTint: Color {
        AppColor.forCourse(recipe.courseValue)
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
            VStack(alignment: .leading, spacing: 0) {
                hero

                VStack(alignment: .leading, spacing: 16) {
                    if let metaLine {
                        Text(metaLine)
                            .font(.subheadline)
                            .foregroundStyle(AppColor.inkMuted)
                    }

                    statRow

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
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ingredients").font(.system(.title3, design: .serif).weight(.bold)).foregroundStyle(AppColor.ink)
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                                ForEach(recipe.ingredients) { ingredient in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .strokeBorder(AppColor.accent, lineWidth: 1.6)
                                            .frame(width: 15, height: 15)
                                            .padding(.top, 2)
                                        Text(ingredientLine(ingredient))
                                            .font(.subheadline)
                                            .foregroundStyle(AppColor.ink)
                                    }
                                }
                            }
                        }
                    }

                    stepSection(title: "Prep", steps: recipe.prepSteps, color: AppColor.accent)
                    stepSection(title: "Cook", steps: recipe.instructionSteps, color: AppColor.secondary)

                    if let sourceURLString = recipe.sourceURL, let url = URL(string: sourceURLString) {
                        Link(destination: url) {
                            Label("View source", systemImage: "link")
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppColor.accent)
                    }

                    Button(role: .destructive) {
                        isPresentingDeleteConfirmation = true
                    } label: {
                        Text("Delete Recipe")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(20)
            }
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
                Button {
                    isPresentingEdit = true
                } label: {
                    Label("Edit", systemImage: "pencil")
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

    @ViewBuilder
    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if !images.isEmpty {
                    TabView {
                        ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .automatic : .never))
                } else {
                    RecipePlaceholderView(glyphSize: 64)
                }
            }

            LinearGradient(
                colors: [heroTint.opacity(0.05), AppColor.ink.opacity(0.4), AppColor.ink.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                if let course = recipe.courseValue {
                    Text(course.rawValue.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(0.4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(heroTint, in: Capsule())
                }
                Text(recipe.title)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                if !recipe.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(recipe.tags.enumerated()), id: \.offset) { index, tag in
                            if index > 0 {
                                Text("·").foregroundStyle(.white.opacity(0.6))
                            }
                            NavigationLink(value: TagFilter(tag: tag)) {
                                Text(tag)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 340)
        .clipped()
    }

    @ViewBuilder
    private var statRow: some View {
        HStack(spacing: 10) {
            if let average = recipe.averageRating {
                statBlock(value: String(format: "%.1f", average), label: "RATING", color: AppColor.gold)
                statBlock(value: "\(recipe.timesCooked)", label: "COOKED", color: AppColor.ink)
            } else {
                statBlock(value: "–", label: "NOT COOKED YET", color: AppColor.inkMuted)
            }

            Button {
                isPresentingLogCook = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(.title2, design: .serif).weight(.bold))
                    Text("LOG A COOK")
                        .font(.caption2.weight(.bold))
                        .tracking(0.3)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColor.secondary, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func statBlock(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.bold))
                .tracking(0.3)
                .foregroundStyle(AppColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColor.surfaceAlt, lineWidth: 1))
    }

    /// A plain numbered list, not a connected stepper — steppers imply active progress
    /// tracking (done/active/upcoming state), which recipe instructions don't have; a
    /// shared connecting line between two unrelated phases just reads as broken. Prep
    /// and Cook are two clearly separate sections, each numbered from 1, distinguished
    /// only by their circle color.
    @ViewBuilder
    private func stepSection(title: String, steps: [String], color: Color) -> some View {
        if !steps.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.system(.title3, design: .serif).weight(.bold)).foregroundStyle(AppColor.ink)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(color, in: Circle())
                            Text(step)
                                .foregroundStyle(AppColor.ink)
                        }
                    }
                }
            }
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
