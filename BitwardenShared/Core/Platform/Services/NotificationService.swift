import BitwardenKit
import BitwardenResources
import Foundation
import OSLog
import UserNotifications

// MARK: - NotificationService

/// A protocol for a service that handles app notifications.
///
protocol NotificationService {
    /// Decodes and saves the push notification token after the device has successfully registered for push
    /// notifications.
    ///
    /// - Parameter tokenData: The data of the push notification token.
    ///
    func didRegister(withToken tokenData: Data) async

    /// Processes any messages received by the application.
    ///
    /// - Parameters:
    ///   - message: The content of the push notification.
    ///   - notificationDismissed: `true` if a notification banner has been dismissed.
    ///   - notificationTapped: `true` if a notification banner has been tapped.
    ///
    func messageReceived(
        _ message: [AnyHashable: Any],
        notificationDismissed: Bool?,
        notificationTapped: Bool?
    ) async

    /// Gets the notification authorization for the device.
    ///
    /// - Returns: The current device UNAuthorizationStatus.
    ///
    func notificationAuthorization() async -> UNAuthorizationStatus

    /// Requests notification authotrization.
    ///
    /// - Parameter options: The `UNAuthorizationOptions` to request.
    /// - Returns: A bool indicating the status.
    ///
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool

    /// Set the delegate for the `NotificationService`.
    ///
    /// - Parameter delegate: The delegate.
    ///
    func setDelegate(_ delegate: NotificationServiceDelegate?)
}

// MARK: - NotificationServiceDelegate

/// The delegate to handle login request actions originating from notifications.
///
@MainActor
protocol NotificationServiceDelegate: AnyObject {
    /// Users are logged out, route to landing page.
    ///
    func routeToLanding() async

    /// Show the login request.
    ///
    /// - Parameter loginRequest: The login request.
    ///
    func showLoginRequest(_ loginRequest: LoginRequest)

    /// Switch the active account in order to show the login request, prompting the user if necessary.
    ///
    /// - Parameters:
    ///   - account: The account associated with the login request.
    ///   - showAlert: Whether to show the alert or simply switch the account.
    ///
    func switchAccountsForLoginRequest(to account: Account, showAlert: Bool) async
}

// MARK: - DefaultNotificationService

/// The default implementation of `NotificationService`.
///
class DefaultNotificationService: NotificationService {
    // MARK: Properties

    /// The delegate to handle login request actions originating from notifications.
    private weak var delegate: NotificationServiceDelegate?

    /// The service used by the application to manage the app's ID.
    private let appIdService: AppIdService

    /// The repository used by the application to manage auth data for the UI layer.
    private let authRepository: AuthRepository

    /// The service used by the application to handle authentication tasks.
    private let authService: AuthService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The API service used to make notification requests.
    private let notificationAPIService: NotificationAPIService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    private let syncService: SyncService

    // MARK: Initialization

    /// Initializes the `DefaultNotificationService`.
    ///
    /// - Parameters:
    ///   - appIdService: The service used by the application to manage the app's ID.
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - authService: The service used by the application to handle authentication tasks.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - notificationAPIService: The API service used to make notification requests.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    init(
        appIdService: AppIdService,
        authRepository: AuthRepository,
        authService: AuthService,
        errorReporter: ErrorReporter,
        notificationAPIService: NotificationAPIService,
        stateService: StateService,
        syncService: SyncService
    ) {
        self.appIdService = appIdService
        self.authRepository = authRepository
        self.authService = authService
        self.errorReporter = errorReporter
        self.notificationAPIService = notificationAPIService
        self.stateService = stateService
        self.syncService = syncService
    }

    // MARK: Methods

    func setDelegate(_ delegate: NotificationServiceDelegate?) {
        self.delegate = delegate
    }

    func didRegister(withToken tokenData: Data) async {
        do {
            // Don't proceed unless the user is authenticated.
            guard try await stateService.isAuthenticated() else { return }

            // Get the app ID.
            let appId = await appIdService.getOrCreateAppId()

            // Decode and save the push notification token.
            let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
            try await notificationAPIService.savePushNotificationToken(for: appId, token: token)

            // Record the date that the token was saved.
            try await stateService.setNotificationsLastRegistrationDate(Date())
        } catch {
            errorReporter.log(error: error)
        }
    }

    func messageReceived( // swiftlint:disable:this function_body_length cyclomatic_complexity
        _ message: [AnyHashable: Any],
        notificationDismissed: Bool?,
        notificationTapped: Bool?
    ) async {
        do {
            // First attempt to decode the message as a response.
            if await handleLoginRequestResponse(
                message,
                notificationDismissed: notificationDismissed,
                notificationTapped: notificationTapped
            ) { return }

            // Proceed to treat the message as new notification.
            guard try await stateService.isAuthenticated(),
                  let notificationData = try await decodePayload(message),
                  let type = notificationData.type
            else { return }
            let userId = try await stateService.getActiveAccountId()

            Logger.application.debug("Notification received: \(message)")

            // Handle the notification according to the type of data.
            switch type {
            case .syncCipherCreate,
                 .syncCipherUpdate:
                if let data: SyncCipherNotification = notificationData.data(), data.userId == userId {
                    try await syncService.fetchUpsertSyncCipher(data: data)
                }
            case .syncFolderCreate,
                 .syncFolderUpdate:
                if let data: SyncFolderNotification = notificationData.data(), data.userId == userId {
                    try await syncService.fetchUpsertSyncFolder(data: data)
                }
            case .syncCipherDelete,
                 .syncLoginDelete:
                if let data: SyncCipherNotification = notificationData.data(), data.userId == userId {
                    try await syncService.deleteCipher(data: data)
                }
            case .syncFolderDelete:
                if let data: SyncFolderNotification = notificationData.data(), data.userId == userId {
                    try await syncService.deleteFolder(data: data)
                }
            case .syncCiphers,
                 .syncSettings,
                 .syncVault:
                try await syncService.fetchSync(forceSync: false)
            case .syncOrgKeys:
                try await syncService.fetchSync(forceSync: true)
            case .logOut:
                guard let data: UserNotification = notificationData.data() else { return }
                try await authRepository.logout(userId: data.userId, userInitiated: true)
                // Only route to landing page if the current active user was logged out.
                if data.userId == userId {
                    await delegate?.routeToLanding()
                }
            case .syncSendCreate,
                 .syncSendUpdate:
                if let data: SyncSendNotification = notificationData.data(), data.userId == userId {
                    try await syncService.fetchUpsertSyncSend(data: data)
                }
            case .syncSendDelete:
                if let data: SyncSendNotification = notificationData.data(), data.userId == userId {
                    try await syncService.deleteSend(data: data)
                }
            case .authRequest:
                try await handleLoginRequest(notificationData, userId: userId)
            case .authRequestResponse:
                // No action necessary, since the LoginWithDeviceProcessor already checks for updates
                // every few seconds.
                break
            }
        } catch {
            errorReporter.log(error: error)
        }
    }

    func notificationAuthorization() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }

    // MARK: Private Methods

    /// A helper function to decode the push notification payload.
    ///
    /// - Parameter message: The content of the push notification.
    ///
    /// - Returns: The decoded push notification data.
    ///
    private func decodePayload(_ message: [AnyHashable: Any]) async throws -> PushNotificationData? {
        // Decode the content of the message.
        guard let messageContent = message["data"] as? [AnyHashable: Any]
        else { return nil }
        let jsonData = try JSONSerialization.data(withJSONObject: messageContent)
        let notificationData = try JSONDecoder().decode(PushNotificationData.self, from: jsonData)

        // Verify that the payload is not empty and that the context is correct.
        let appId = await appIdService.getOrCreateAppId()
        guard notificationData.payload?.isEmpty == false,
              notificationData.contextId != appId
        else { return nil }
        return notificationData
    }

    /// A helper method to handle a login request push notification.
    ///
    /// - Parameters:
    ///   - notificationData: The decoded payload from the push notification.
    ///   - userId: The user's id.
    ///
    private func handleLoginRequest(_ notificationData: PushNotificationData, userId: String) async throws {
        guard let data: LoginRequestNotification = notificationData.data() else { return }

        // Save the notification data.
        await stateService.setLoginRequest(data)

        // Get the email of the account that the login request is coming from.
        let loginSourceAccount = try await stateService.getAccount(userId: data.userId)
        let loginSourceEmail = loginSourceAccount.profile.email

        // Assemble the data to add to the in-app banner notification.
        let loginRequestData = try? JSONEncoder().encode(LoginRequestPushNotification(
            timeoutInMinutes: Constants.loginRequestTimeoutMinutes,
            userId: loginSourceAccount.profile.userId
        ))

        // Create an in-app banner notification to tell the user about the login request.
        let content = UNMutableNotificationContent()
        content.title = Localizations.logInRequested
        content.body = Localizations.confimLogInAttempForX(loginSourceEmail)
        content.categoryIdentifier = "dismissableCategory"
        if let loginRequestData,
           let loginRequestEncoded = String(data: loginRequestData, encoding: .utf8) {
            content.userInfo = ["notificationData": loginRequestEncoded]
        }
        let category = UNNotificationCategory(
            identifier: "dismissableCategory",
            actions: [.init(identifier: "Clear", title: Localizations.clear, options: [.foreground])],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
        let request = UNNotificationRequest(identifier: data.id, content: content, trigger: nil)
        try await UNUserNotificationCenter.current().add(request)

        if data.userId == userId {
            // If the request is for the existing account, show the login request view automatically.
            guard let loginRequest = try await authService.getPendingLoginRequest(withId: data.id).first
            else { return }
            await delegate?.showLoginRequest(loginRequest)
        } else {
            // Otherwise, show an alert asking the user if they want to switch accounts.
            await delegate?.switchAccountsForLoginRequest(to: loginSourceAccount, showAlert: true)
        }
    }

    /// Attempt to decode the notification data as a response to a login notification banner.
    ///
    /// - Parameters:
    ///   - message: The content of the push notification.
    ///   - notificationDismissed: `true` if a notification banner has been dismissed.
    ///   - notificationTapped: `true` if a notification banner has been tapped.
    ///
    /// - Returns: `true` if the message was able to be decoded as a response.
    ///
    private func handleLoginRequestResponse(
        _ message: [AnyHashable: Any],
        notificationDismissed: Bool?,
        notificationTapped: Bool?
    ) async -> Bool {
        if let content = message["notificationData"] as? String,
           let jsonData = content.data(using: .utf8),
           let loginRequestData = try? JSONDecoder.pascalOrSnakeCaseDecoder.decode(
               LoginRequestPushNotification.self,
               from: jsonData
           ) {
            if notificationDismissed == true {
                await handleNotificationDismissed()
                return true
            }
            if notificationTapped == true {
                await handleNotificationTapped(loginRequestData)
                return true
            }
        }
        return false
    }

    /// Handle a banner notification being dismissed.
    private func handleNotificationDismissed() async {
        // If the notification banner was dismissed, clear the cached value.
        await stateService.setLoginRequest(nil)
    }

    /// Handle a banner notification with login request data being tapped.
    private func handleNotificationTapped(_ loginRequestData: LoginRequestPushNotification) async {
        do {
            // Get the user id of the source of the login request.
            let loginSourceAccount = try await stateService.getAccount(userId: loginRequestData.userId)

            // Get the active account for comparison.
            let activeAccount = try await stateService.getActiveAccount()

            // If the notification banner was tapped but it's for a different account, switch
            // to that account automatically.
            if activeAccount.profile.userId != loginSourceAccount.profile.userId {
                await delegate?.switchAccountsForLoginRequest(to: loginSourceAccount, showAlert: false)
            }
        } catch {
            errorReporter.log(error: error)
        }
    }
}
