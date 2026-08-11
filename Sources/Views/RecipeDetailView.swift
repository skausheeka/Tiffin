import SwiftUI
import UIKit

struct RecipeDetailView: View {
    let recipe: Recipe

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

                if !recipe.tags.isEmpty {
                    Text(recipe.tags.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let metaLine {
                    Text(metaLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !recipe.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ingredients").font(.title3.bold())
                        ForEach(recipe.ingredients) { ingredient in
                            Text("• \(ingredientLine(ingredient))")
                        }
                    }
                }

                if !recipe.instructionSteps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions").font(.title3.bold())
                        ForEach(Array(recipe.instructionSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .foregroundStyle(.secondary)
                                Text(step)
                            }
                        }
                    }
                }

                if let sourceURLString = recipe.sourceURL, let url = URL(string: sourceURLString) {
                    Link(destination: url) {
                        Label("View source", systemImage: "link")
                    }
                    .font(.subheadline)
                }
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
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
