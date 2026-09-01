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

    /// Prep and cook steps merged into one ordered sequence — each entry knows whether
    /// it's a prep or cook step (for the timeline's dot color) and carries a phase
    /// label only on the first step of that phase.
    private var timelineSteps: [(phase: String?, text: String, isPrep: Bool)] {
        var result: [(phase: String?, text: String, isPrep: Bool)] = []
        for (index, step) in recipe.prepSteps.enumerated() {
            result.append((index == 0 ? "Prep" : nil, step, true))
        }
        for (index, step) in recipe.instructionSteps.enumerated() {
            result.append((index == 0 ? "Cook" : nil, step, false))
        }
        return result
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

                    if !timelineSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Method").font(.system(.title3, design: .serif).weight(.bold)).foregroundStyle(AppColor.ink)
                            methodTimeline
                        }
                    }

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

    @ViewBuilder
    private var methodTimeline: some View {
        let prepFraction = recipe.prepSteps.isEmpty ? 0 : Double(recipe.prepSteps.count) / Double(max(timelineSteps.count, 1))

        ZStack(alignment: .topLeading) {
            LinearGradient(
                stops: recipe.prepSteps.isEmpty
                    ? [Gradient.Stop(color: AppColor.secondary, location: 0), Gradient.Stop(color: AppColor.secondary, location: 1)]
                    : [
                        Gradient.Stop(color: AppColor.accent, location: 0),
                        Gradient.Stop(color: AppColor.accent, location: prepFraction),
                        Gradient.Stop(color: AppColor.secondary, location: prepFraction),
                        Gradient.Stop(color: AppColor.secondary, location: 1),
                    ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 2)
            .padding(.leading, 9)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(timelineSteps.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(item.isPrep ? AppColor.accent : AppColor.secondary, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            if let phase = item.phase {
                                Text(phase.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .tracking(0.3)
                                    .foregroundStyle(item.isPrep ? AppColor.accent : AppColor.secondary)
                            }
                            Text(item.text)
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
