import Foundation
import SwiftData

@Model
final class MealPlanEntry {
    var date: Date
    var servings: Int?
    var expectsLeftovers: Bool
    var recipe: Recipe?

    init(
        date: Date,
        recipe: Recipe,
        servings: Int? = nil,
        expectsLeftovers: Bool = false
    ) {
        self.date = date
        self.recipe = recipe
        self.servings = servings
        self.expectsLeftovers = expectsLeftovers
    }
}
