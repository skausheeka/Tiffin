import Foundation
import SwiftData

@Model
final class MealPlanEntry {
    var date: Date = Date.now
    var servings: Int?
    var expectsLeftovers: Bool = false
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
