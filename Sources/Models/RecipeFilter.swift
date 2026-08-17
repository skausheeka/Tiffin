import Foundation

enum TimeBucket: String, CaseIterable, Identifiable {
    case under30 = "Under 30 min"
    case thirtyToSixty = "30–60 min"
    case over60 = "Over 60 min"

    var id: String { rawValue }

    func matches(totalMinutes: Int) -> Bool {
        switch self {
        case .under30: totalMinutes < 30
        case .thirtyToSixty: (30...60).contains(totalMinutes)
        case .over60: totalMinutes > 60
        }
    }
}

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

/// A combined set of card-grid filters — cuisine, course, time to cook, and
/// times cooked — all optional and applied together (AND, not OR).
struct RecipeFilter: Equatable {
    var cuisine: String?
    var course: RecipeCourse?
    var timeBucket: TimeBucket?
    var cookedBucket: CookedBucket?

    var isActive: Bool {
        cuisine != nil || course != nil || timeBucket != nil || cookedBucket != nil
    }

    var activeCount: Int {
        [cuisine != nil, course != nil, timeBucket != nil, cookedBucket != nil]
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
        if let timeBucket {
            let total = (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)
            guard total > 0, timeBucket.matches(totalMinutes: total) else { return false }
        }
        if let cookedBucket, !cookedBucket.matches(timesCooked: recipe.timesCooked) {
            return false
        }
        return true
    }
}
