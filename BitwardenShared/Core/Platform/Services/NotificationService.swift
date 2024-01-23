import Foundation
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

    /// Set the delegate for the `NotificationService`.
    ///
    /// - Parameter delegate: The delegate.
    ///
    func setDelegate(_ delegate: NotificationServiceDelegate?)
}

// MARK: - NotificationServiceDelegate

/// The delegate to handle login request actions originating from notifications.
///
protocol NotificationServiceDelegate: AnyObject {
    /// Show the login request.
    ///
    /// - Parameter loginRequest: The login request.
    ///
    func showLoginRequest(_ loginRequest: LoginRequest)

    /// Switch the active account in order to show the login request, prompting the user if necessary.
    ///
    /// - Parameters:
    ///   - account: The account associated with the login request.
    ///   - loginRequest: The login request to show.
    ///   - showAlert: Whether to show the alert or simply switch the account.
    ///
    func switchAccounts(to account: Account, for loginRequest: LoginRequest, showAlert: Bool)
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
    ///   - authService: The service used by the application to handle authentication tasks.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - notificationAPIService: The API service used to make notification requests.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    init(
        appIdService: AppIdService,
        authService: AuthService,
        errorReporter: ErrorReporter,
        notificationAPIService: NotificationAPIService,
        stateService: StateService,
        syncService: SyncService
    ) {
        self.appIdService = appIdService
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
            guard await stateService.isAuthenticated() else { return }

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
            if let content = message["notificationData"] as? String,
               let jsonData = content.data(using: .utf8),
               let loginRequestData = try? JSONDecoder.pascalOrSnakeCaseDecoder.decode(
                   LoginRequestPushNotification.self,
                   from: jsonData
               ) {
                if notificationDismissed == true { return await handleNotificationDismissed() }
                if notificationTapped == true { return await handleNotificationTapped(loginRequestData) }
            }

            // Proceed to treat the message as new notification.
            let appId = await appIdService.getOrCreateAppId()
            let isAuthenticated = await stateService.isAuthenticated()
            let userId = try await stateService.getActiveAccountId()

            // Decode the content of the message.
            guard let messageData = message["aps"] as? [AnyHashable: Any],
                  let messageContent = messageData["data"] as? [AnyHashable: Any]
            else { return }
            let jsonData = try JSONSerialization.data(withJSONObject: messageContent)
            let notificationData = try JSONDecoder().decode(PushNotificationData.self, from: jsonData)

            guard let type = notificationData.type,
                  notificationData.payload?.isEmpty == false,
                  notificationData.contextId != appId,
                  isAuthenticated
            else { return }

            // Handle the notification according to the type of data.
            switch type {
            case .syncCipherCreate,
                 .syncCipherUpdate:
                if let data: SyncCipherNotification = notificationData.data(), data.userId == userId {
                    // TODO: BIT-1528 "SyncUpsertCipherAsync"
                }
            case .syncFolderCreate,
                 .syncFolderUpdate:
                if let data: SyncFolderNotification = notificationData.data(), data.userId == userId {
                    // TODO: BIT-1528 "SyncUpsertFolderAsync"
                }
            case .syncCipherDelete,
                 .syncLoginDelete:
                if let data: SyncCipherNotification = notificationData.data(), data.userId == userId {
                    // TODO: BIT-1528 "SyncDeleteCipherAsync"
                }
            case .syncFolderDelete:
                if let data: SyncFolderNotification = notificationData.data(), data.userId == userId {
                    // TODO: BIT-1528 "SyncDeleteFolderAsync"
                }
            case .syncCiphers,
                 .syncSettings,
                 .syncVault:
                try await syncService.fetchSync()
            case .syncOrgKeys:
                // TODO: BIT-1528 call api to refresh token
                // try await authAPIService.refreshIdentityToken(refreshToken: ???)
                try await syncService.fetchSync()
            case .logOut:
                break
            case .syncSendCreate,
                 .syncSendUpdate:
                if let data: SyncSendNotification = notificationData.data(), data.userId == userId {
                    // TODO: BIT-1528 "SyncUpsertSendAsync"
                }
            case .syncSendDelete:
                if let data: SyncSendNotification = notificationData.data(), data.userId == userId {
                    // TODO: BIT-1528 "SyncDeleteSendAsync"
                }
            case .authRequest:
                let approveLoginRequests = try? await stateService.getApproveLoginRequests()
                guard let data: LoginRequestNotification = notificationData.data(),
                      approveLoginRequests == true
                else { return }

                // Save the notification data.
                await stateService.setLoginRequest(data)

                // Get the email of the account that the login request is coming from.
                let loginSourceAccount = try await stateService.getAccounts()
                    .first(where: { $0.profile.userId == data.userId })
                let loginSourceEmail = loginSourceAccount?.profile.email ?? ""

                // Assemble the data to add to the in-app banner notification.
                let loginRequestData = try? JSONEncoder().encode(LoginRequestPushNotification(
                    timeoutInMinutes: Constants.loginRequestTimeoutMinutes,
                    userEmail: loginSourceEmail
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

                // If the request is for the existing account, show the login request view automatically.
                guard let loginRequest = try await authService.getPendingLoginRequest(withId: data.id).first
                else { return }
                if data.userId == userId {
                    delegate?.showLoginRequest(loginRequest)
                } else if let loginSourceAccount {
                    // Otherwise, show an alert asking the user if they want to switch accounts.
                    delegate?.switchAccounts(to: loginSourceAccount, for: loginRequest, showAlert: true)
                }
            case .authRequestResponse:
                // No action necessary, since the LoginWithDeviceProcessor already checks for updates
                // every few seconds.
                break
            }
        } catch {
            errorReporter.log(error: error)
        }
    }

    // MARK: Private Methods

    /// Handle a banner notification being dismissed.
    private func handleNotificationDismissed() async {
        // If the notification banner was dismissed, clear the cached value.
        await stateService.setLoginRequest(nil)
    }

    /// Handle a banner notification with login request data being tapped.
    private func handleNotificationTapped(_ loginRequestData: LoginRequestPushNotification) async {
        do {
            // Get the user id of the source of the login request.
            guard let loginSourceAccount = try await stateService.getAccounts()
                .first(where: { $0.profile.email == loginRequestData.userEmail })
            else { return }

            // Get the active account for comparison.
            let activeAccount = try await stateService.getActiveAccount()

            // If the notification banner was tapped but it's for a different account, switch
            // to that account automatically.
            if activeAccount.profile.userId != loginSourceAccount.profile.userId,
               let loginRequestData = await stateService.getLoginRequest(),
               let loginRequest = try await authService.getPendingLoginRequest(withId: loginRequestData.id).first {
                try await stateService.setActiveAccount(userId: loginSourceAccount.profile.userId)
                delegate?.switchAccounts(to: loginSourceAccount, for: loginRequest, showAlert: false)
            }
        } catch {
            errorReporter.log(error: error)
        }
    }
}
