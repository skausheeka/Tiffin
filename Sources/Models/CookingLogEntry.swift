import Foundation
import SwiftData

@Model
final class CookingLogEntry {
    var date: Date = Date.now
    var rating: Int = 0
    var note: String?
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    var photoFilename: String?
    var recipe: Recipe?

    init(
        date: Date = .now,
        rating: Int,
        note: String? = nil,
        prepTimeMinutes: Int? = nil,
        cookTimeMinutes: Int? = nil,
        photoFilename: String? = nil,
        recipe: Recipe
    ) {
        self.date = date
        self.rating = rating
        self.note = note
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.photoFilename = photoFilename
        self.recipe = recipe
    }
}
