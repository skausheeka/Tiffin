import Foundation
import SwiftData

@Model
final class Recipe {
    var title: String
    var ingredients: [IngredientEntry]
    var instructionSteps: [String]
    var tags: [String]
    var createdAt: Date
    var photoFilenames: [String]
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    var servings: Int?
    var sourceURL: String?

    init(
        title: String,
        ingredients: [IngredientEntry] = [],
        instructionSteps: [String] = [],
        tags: [String] = [],
        createdAt: Date = .now,
        photoFilenames: [String] = [],
        prepTimeMinutes: Int? = nil,
        cookTimeMinutes: Int? = nil,
        servings: Int? = nil,
        sourceURL: String? = nil
    ) {
        self.title = title
        self.ingredients = ingredients
        self.instructionSteps = instructionSteps
        self.tags = tags
        self.createdAt = createdAt
        self.photoFilenames = photoFilenames
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.servings = servings
        self.sourceURL = sourceURL
    }

    var coverPhotoFilename: String? {
        photoFilenames.first
    }
}
