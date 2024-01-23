import Foundation

// MARK: - NotificationService

/// A protocol for a service that handles app notifications.
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
    func messageReceived(_ message: [AnyHashable: Any], notificationDismissed: Bool?, notificationTapped: Bool?) async
}

// MARK: - DefaultNotificationService

/// The default implementation of `NotificationService`.
///
class DefaultNotificationService: NotificationService {
    // MARK: Properties

    /// The service used by the application to manage the app's ID.
    private let appIdService: AppIdService

    /// The API service used to make calls related to the auth process.
    private let authAPIService: AuthAPIService

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
    ///   - authAPIService: The API service used to make calls related to the auth process.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - notificationAPIService: The API service used to make notification requests.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    init(
        appIdService: AppIdService,
        authAPIService: AuthAPIService,
        errorReporter: ErrorReporter,
        notificationAPIService: NotificationAPIService,
        stateService: StateService,
        syncService: SyncService
    ) {
        self.appIdService = appIdService
        self.authAPIService = authAPIService
        self.errorReporter = errorReporter
        self.notificationAPIService = notificationAPIService
        self.stateService = stateService
        self.syncService = syncService
    }

    // MARK: Methods

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
                  isAuthenticated || notificationData.type == .authRequestResponse
            else { return }

            // Handle the notification according to the type of data.
            switch type {
            case .syncCipherCreate,
                 .syncCipherUpdate:
                if let data: SyncCipherNotification? = notificationData.data(), data?.userId == userId {
                    // TODO: BIT-1528 "SyncUpsertCipherAsync"
                }
            case .syncFolderCreate,
                 .syncFolderUpdate:
                if let data: SyncFolderNotification? = notificationData.data(), data?.userId == userId {
                    // TODO: BIT-1528 "SyncUpsertFolderAsync"
                }
            case .syncCipherDelete,
                 .syncLoginDelete:
                if let data: SyncCipherNotification? = notificationData.data(), data?.userId == userId {
                    // TODO: BIT-1528 "SyncDeleteCipherAsync"
                }
            case .syncFolderDelete:
                if let data: SyncFolderNotification? = notificationData.data(), data?.userId == userId {
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
                if let data: SyncSendNotification? = notificationData.data(), data?.userId == userId {
                    // TODO: BIT-1528 "SyncUpsertSendAsync"
                }
            case .syncSendDelete:
                if let data: SyncSendNotification? = notificationData.data(), data?.userId == userId {
                    // TODO: BIT-1528 "SyncDeleteSendAsync"
                }
            case .authRequest:
                let approveLoginRequests = try? await stateService.getApproveLoginRequests()
                guard let data: LoginRequestNotification? = notificationData.data(),
                      approveLoginRequests == true
                else { return }

                // If the notification banner was tapped but it's for a different account, switch to that account.
                if notificationTapped == true {
                    // TODO: BIT-1529
                } else if notificationDismissed == true {
                    // If the notification banner was dismissed, clear the value in the state service for
                    // `SetPasswordlessLoginNotificationAsync`.
                    // TODO: BIT-1529
                } else if data?.userId == userId {
                    // TODO: BIT-1529 display the LoginRequestView
                    // Check if a view is already presented, and if so, don't show a new view.
                    // Save the data to the state service as `SetPasswordlessLoginNotificationAsync`
                    // Show an in-app banner.
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
}
