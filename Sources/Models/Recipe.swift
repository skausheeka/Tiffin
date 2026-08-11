import Foundation
import SwiftData

@Model
final class Recipe {
    var title: String
    var ingredients: [String]
    var instructions: String
    var tags: [String]
    var createdAt: Date

    init(
        title: String,
        ingredients: [String] = [],
        instructions: String = "",
        tags: [String] = [],
        createdAt: Date = .now
    ) {
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.tags = tags
        self.createdAt = createdAt
    }
}
