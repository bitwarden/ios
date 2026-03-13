import BitwardenKit
import BitwardenResources
import Foundation
import UserNotifications

// MARK: - NotificationExtensionHelper

/// A protocol for a helper that processes notification content within a notification service extension.
///
public protocol NotificationExtensionHelper { // sourcery: AutoMockable
    /// Processes a notification, updating the content as appropriate based on its type.
    ///
    /// - Parameter content: The mutable notification content to update.
    /// - Returns: The updated notification content, or the original content unchanged if the
    ///   payload cannot be decoded or no update applies.
    ///
    func processNotification(
        content: UNMutableNotificationContent,
    ) async -> UNMutableNotificationContent
}

// MARK: - DefaultNotificationExtensionHelper

/// The default implementation of `NotificationExtensionHelper`.
///
public class DefaultNotificationExtensionHelper: NotificationExtensionHelper {
    // MARK: Properties

    /// The store used to read persisted app settings.
    private let appSettingsStore: AppSettingsStore

    /// The reporter used to log non-fatal errors.
    private let errorReporter: ErrorReporter

    // MARK: Initialization

    /// Initializes a `DefaultNotificationExtensionHelper` with an explicit settings store
    /// and error reporter.
    ///
    /// - Parameters:
    ///   - appSettingsStore: The store used to read persisted app settings.
    ///   - errorReporter: The reporter used to log non-fatal errors.
    ///
    init(appSettingsStore: AppSettingsStore, errorReporter: ErrorReporter) {
        self.appSettingsStore = appSettingsStore
        self.errorReporter = errorReporter

        Resources.initialLanguageCode = appSettingsStore.appLocale ?? Bundle.main.preferredLocalizations.first
    }

    /// Initializes a `DefaultNotificationExtensionHelper` using the shared app group `UserDefaults`
    /// and an `OSLogErrorReporter`.
    ///
    public convenience init() {
        let userDefaults = UserDefaults(suiteName: Bundle.main.groupIdentifier)!
        self.init(
            appSettingsStore: DefaultAppSettingsStore(userDefaults: userDefaults),
            errorReporter: OSLogErrorReporter(),
        )
    }

    // MARK: NotificationExtensionHelper

    public func processNotification(content: UNMutableNotificationContent) async -> UNMutableNotificationContent {
        do {
            guard let notificationData = try decodePushNotificationData(from: content.userInfo),
                  let type = notificationData.type
            else {
                return content
            }

            switch type {
            case .authRequest:
                return try handleAuthRequest(notificationData, content: content)
            default:
                return content
            }
        } catch {
            errorReporter.log(error: error)
            return content
        }
    }

    // MARK: Private

    /// Decodes a `PushNotificationData` from a notification's `userInfo` dictionary.
    ///
    /// - Parameter userInfo: The notification's `userInfo` dictionary.
    /// - Returns: The decoded `PushNotificationData`, or `nil` if the `"data"` key is absent.
    /// - Throws: An error if JSON serialization or decoding fails.
    ///
    private func decodePushNotificationData(from userInfo: [AnyHashable: Any]) throws -> PushNotificationData? {
        guard let messageContent = userInfo["data"] as? [AnyHashable: Any] else { return nil }
        let jsonData = try JSONSerialization.data(withJSONObject: messageContent)
        return try JSONDecoder().decode(PushNotificationData.self, from: jsonData)
    }

    /// Handles an auth request notification, updating the body with the requesting user's email
    /// if found in the accounts store.
    ///
    /// - Parameters:
    ///   - notificationData: The decoded push notification data.
    ///   - content: The mutable notification content to update.
    /// - Returns: The updated content, or the original content unchanged if the user is not found.
    /// - Throws: An error if the login request payload cannot be decoded.
    ///
    private func handleAuthRequest(
        _ notificationData: PushNotificationData,
        content: UNMutableNotificationContent,
    ) throws -> UNMutableNotificationContent {
        let loginRequest: LoginRequestNotification = try notificationData.data()
        guard let email = appSettingsStore.state?.accounts[loginRequest.userId]?.profile.email else {
            return content
        }

        content.title = Localizations.logInRequested
        content.body = Localizations.confimLogInAttempForX(email)

        return content
    }
}
