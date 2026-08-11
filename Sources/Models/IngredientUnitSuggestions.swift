import Foundation

enum IngredientUnitSuggestions {
    private static let table: [String: String] = [
        "flour": "cup",
        "all-purpose flour": "cup",
        "sugar": "cup",
        "brown sugar": "cup",
        "powdered sugar": "cup",
        "rice": "cup",
        "oats": "cup",
        "bread crumbs": "cup",
        "breadcrumbs": "cup",

        "milk": "cup",
        "water": "cup",
        "heavy cream": "cup",
        "buttermilk": "cup",
        "coconut milk": "cup",
        "broth": "cup",
        "chicken broth": "cup",
        "vegetable broth": "cup",
        "stock": "cup",

        "olive oil": "tbsp",
        "vegetable oil": "tbsp",
        "butter": "tbsp",
        "honey": "tbsp",
        "maple syrup": "tbsp",
        "soy sauce": "tbsp",
        "vinegar": "tbsp",
        "balsamic vinegar": "tbsp",
        "lemon juice": "tbsp",
        "lime juice": "tbsp",
        "tomato paste": "tbsp",
        "mayonnaise": "tbsp",
        "mustard": "tbsp",

        "salt": "tsp",
        "pepper": "tsp",
        "black pepper": "tsp",
        "cinnamon": "tsp",
        "cumin": "tsp",
        "paprika": "tsp",
        "nutmeg": "tsp",
        "baking soda": "tsp",
        "baking powder": "tsp",
        "vanilla extract": "tsp",
        "chili powder": "tsp",
        "garlic powder": "tsp",
        "onion powder": "tsp",
        "oregano": "tsp",
        "basil": "tsp",
        "thyme": "tsp",
        "cayenne": "tsp",
        "red pepper flakes": "tsp",
        "cornstarch": "tsp",

        "eggs": "whole",
        "egg": "whole",
        "onion": "whole",
        "potato": "whole",
        "potatoes": "whole",
        "carrot": "whole",
        "carrots": "whole",
        "garlic": "clove",
        "garlic cloves": "clove",

        "chicken breast": "lb",
        "ground beef": "lb",
        "bacon": "oz",
        "cheese": "oz",
        "cheddar cheese": "oz",
        "parmesan": "oz",
        "mozzarella": "oz",
        "pasta": "oz",
    ]

    static func suggestedUnit(for ingredientName: String) -> String? {
        let name = ingredientName.lowercased().trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }

        if let exact = table[name] {
            return exact
        }

        let matches = table.keys.filter { name.contains($0) }
        return matches.max(by: { $0.count < $1.count }).flatMap { table[$0] }
    }
}
