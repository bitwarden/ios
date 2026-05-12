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
            let notificationData = try PushNotificationData(userInfo: content.userInfo)
            guard let type = notificationData.type else {
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
        content.body = Localizations.confirmLogInAttemptForX(email)

        return content
    }
}
