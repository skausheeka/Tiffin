import Foundation

struct IngredientEntry: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var amount: Double?
    var unit: String

    init(id: UUID = UUID(), name: String = "", amount: Double? = nil, unit: String = "") {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
    }
}
