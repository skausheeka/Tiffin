import Foundation
import Observation

/// Bridges a tapped cook-log-reminder notification (handled by `NotificationDelegate`,
/// which is plain `NSObject` — not a SwiftUI view and can't present anything itself)
/// into the view layer. `RootTabView` observes `pendingEntryID` and, once set, resolves
/// it to a live `MealPlanEntry` in its own `modelContext` and presents the Log a Cook
/// sheet.
@Observable
final class CookLogDeepLinkRouter {
    static let shared = CookLogDeepLinkRouter()

    var pendingEntryID: UUID?

    private init() {}
}
