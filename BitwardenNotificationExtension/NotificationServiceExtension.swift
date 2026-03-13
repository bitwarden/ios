import BitwardenShared
import OSLog
import UserNotifications

// MARK: - NotificationServiceExtension

/// The notification service extension entry point, responsible for intercepting incoming alert
/// push notifications and updating their content before delivery.
///
/// This class is intentionally thin — all decoding and state-lookup logic lives in
/// `DefaultNotificationExtensionHelper` (in `BitwardenShared`) where it is fully testable.
///
class NotificationServiceExtension: UNNotificationServiceExtension {
    // MARK: UNNotificationServiceExtension

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void,
    ) {
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            Logger.appExtension.error("Failed to cast UNNotificationContent to UNMutableNotificationContent")
            contentHandler(request.content)
            return
        }

        Task {
            let updatedContent = await DefaultNotificationExtensionHelper().processNotification(content: content)
            contentHandler(updatedContent)
        }
    }
}
