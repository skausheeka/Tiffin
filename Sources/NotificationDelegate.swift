import UserNotifications

/// Set as `UNUserNotificationCenter.current().delegate` from `RecipeAppApp.init()`.
/// This app has no `UIApplicationDelegateAdaptor`, so this plain object is the only
/// hook available to react to a notification tap — it can't present UI itself, so it
/// just hands the tapped entry's id to `CookLogDeepLinkRouter` for `RootTabView` to act on.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let idString = response.notification.request.content.userInfo["mealPlanEntryID"] as? String,
           let id = UUID(uuidString: idString) {
            CookLogDeepLinkRouter.shared.pendingEntryID = id
        }
        completionHandler()
    }

    /// Show the banner even while the app is already open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
