import Foundation

enum RecipeCourse: String, CaseIterable, Identifiable, Codable {
    case breakfast = "Breakfast"
    case appetizer = "Appetizer"
    case entree = "Entree"
    case side = "Side"
    case snack = "Snack"
    case dessert = "Dessert"

    var id: String { rawValue }
}
