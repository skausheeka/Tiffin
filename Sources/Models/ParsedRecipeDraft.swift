import Foundation

/// The result of parsing a recipe from a pasted URL or block of text — never persisted directly;
/// used only to prefill `AddRecipeView` for the user to review before saving.
struct ParsedRecipeDraft: Equatable {
    var title: String
    var ingredients: [IngredientEntry]
    var steps: [String]
    var course: RecipeCourse?
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    var servings: Int?
    var tags: [String]
    var sourceURL: String?
}
