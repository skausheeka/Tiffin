import Foundation

enum CookedBucket: String, CaseIterable, Identifiable {
    case never = "Never cooked"
    case oneOrTwo = "Cooked 1–2 times"
    case threePlus = "Cooked 3+ times"

    var id: String { rawValue }

    func matches(timesCooked: Int) -> Bool {
        switch self {
        case .never: timesCooked == 0
        case .oneOrTwo: (1...2).contains(timesCooked)
        case .threePlus: timesCooked >= 3
        }
    }
}

/// A combined set of card-grid filters — cuisine, course, a max time-to-cook
/// threshold, and times cooked — all optional and applied together (AND, not OR).
struct RecipeFilter: Equatable {
    var cuisine: String?
    var course: RecipeCourse?
    /// Recipes whose prep + cook time is at or under this many minutes. `nil` means no
    /// constraint — an exact, adjustable threshold rather than a fixed bucket, since
    /// "under 40 minutes" is a perfectly normal ask that a 30/60 split can't express.
    var maxCookTimeMinutes: Int?
    var cookedBucket: CookedBucket?

    var isActive: Bool {
        cuisine != nil || course != nil || maxCookTimeMinutes != nil || cookedBucket != nil
    }

    var activeCount: Int {
        [cuisine != nil, course != nil, maxCookTimeMinutes != nil, cookedBucket != nil]
            .filter { $0 }
            .count
    }

    func matches(_ recipe: Recipe) -> Bool {
        if let cuisine, recipe.tags.first != cuisine {
            return false
        }
        if let course, recipe.courseValue != course {
            return false
        }
        if let maxCookTimeMinutes {
            let total = (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)
            guard total > 0, total <= maxCookTimeMinutes else { return false }
        }
        if let cookedBucket, !cookedBucket.matches(timesCooked: recipe.timesCooked) {
            return false
        }
        return true
    }
}
