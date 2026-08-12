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
    var course: String?
    var rating: Int?
    var note: String?
    var timesCooked: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \MealPlanEntry.recipe) var mealPlanEntries: [MealPlanEntry] = []

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
        sourceURL: String? = nil,
        course: RecipeCourse? = nil,
        rating: Int? = nil,
        note: String? = nil,
        timesCooked: Int = 0
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
        self.course = course?.rawValue
        self.rating = rating
        self.note = note
        self.timesCooked = timesCooked
    }

    var courseValue: RecipeCourse? {
        course.flatMap(RecipeCourse.init(rawValue:))
    }

    var coverPhotoFilename: String? {
        photoFilenames.first
    }

    /// Rated recipes only, highest rating first, ties broken by times cooked.
    static func ranked(_ recipes: [Recipe]) -> [Recipe] {
        recipes
            .filter { $0.rating != nil }
            .sorted { lhs, rhs in
                let lhsRating = lhs.rating ?? 0
                let rhsRating = rhs.rating ?? 0
                if lhsRating != rhsRating { return lhsRating > rhsRating }
                return lhs.timesCooked > rhs.timesCooked
            }
    }

    /// Trims each row's name/unit and drops rows left with no name (e.g. a blank trailing row).
    static func cleanIngredients(_ rows: [IngredientEntry]) -> [IngredientEntry] {
        rows
            .map { entry -> IngredientEntry in
                var cleaned = entry
                cleaned.name = entry.name.trimmingCharacters(in: .whitespaces)
                cleaned.unit = entry.unit.trimmingCharacters(in: .whitespaces)
                return cleaned
            }
            .filter { !$0.name.isEmpty }
    }

    /// Trims each step and drops any left blank (e.g. an untouched trailing step).
    static func cleanSteps(_ steps: [String]) -> [String] {
        steps
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Splits comma-separated tag input, trimming whitespace and dropping empty entries.
    static func parseTags(_ text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
