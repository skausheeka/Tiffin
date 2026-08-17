import Foundation
import SwiftData

@Model
final class CookingLogEntry {
    var date: Date = Date.now
    var rating: Int = 0
    var note: String?
    var recipe: Recipe?

    init(
        date: Date = .now,
        rating: Int,
        note: String? = nil,
        recipe: Recipe
    ) {
        self.date = date
        self.rating = rating
        self.note = note
        self.recipe = recipe
    }
}
