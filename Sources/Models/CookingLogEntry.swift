import Foundation
import SwiftData

@Model
final class CookingLogEntry {
    var date: Date = Date.now
    var rating: Int = 0
    var timeMinutes: Int = 0
    var note: String?
    var photoFilename: String?
    var recipe: Recipe?

    init(
        date: Date = .now,
        rating: Int,
        timeMinutes: Int,
        note: String? = nil,
        photoFilename: String? = nil,
        recipe: Recipe
    ) {
        self.date = date
        self.rating = rating
        self.timeMinutes = timeMinutes
        self.note = note
        self.photoFilename = photoFilename
        self.recipe = recipe
    }
}
