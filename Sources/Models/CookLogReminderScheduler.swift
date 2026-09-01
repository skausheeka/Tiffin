import Foundation
import UserNotifications

/// Schedules a local reminder ~90 minutes after a planned meal's time, nudging the
/// user to log the cook — rate it and record how long it actually took. Tapping the
/// notification routes through `CookLogDeepLinkRouter` to open a pre-filled Log a Cook
/// sheet (see `NotificationDelegate` and `RootTabView`).
enum CookLogReminderScheduler {
    /// Long enough that you've plausibly finished cooking and eating, short enough
    /// that it's still top-of-mind that evening.
    static let reminderDelay: TimeInterval = 90 * 60

    /// Pure — the actual moment a reminder for `entryDate` should fire.
    static func fireDate(for entryDate: Date) -> Date {
        entryDate.addingTimeInterval(reminderDelay)
    }

    static func requestAuthorizationIfNeeded() {
        // Safe to call every time — only actually prompts the user the first time;
        // afterward it just resolves with whatever they already decided.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func schedule(for entry: MealPlanEntry) {
        let center = UNUserNotificationCenter.current()
        let identifier = notificationIdentifier(for: entry)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard let recipe = entry.recipe else { return }
        let fireDate = fireDate(for: entry.date)
        let interval = fireDate.timeIntervalSinceNow
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "How did \(recipe.title) turn out?"
        content.body = "Log this cook to rate it and record how long it took."
        content.sound = .default
        content.userInfo = ["mealPlanEntryID": entry.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    static func cancel(for entry: MealPlanEntry) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier(for: entry)])
    }

    private static func notificationIdentifier(for entry: MealPlanEntry) -> String {
        "cookLogReminder-\(entry.id.uuidString)"
    }
}
