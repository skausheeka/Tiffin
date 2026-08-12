import Foundation

enum RecipeCourse: String, CaseIterable, Identifiable, Codable {
    case appetizer = "Appetizer"
    case entree = "Entree"
    case dessert = "Dessert"

    var id: String { rawValue }
}
