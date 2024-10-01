import AuthenticatorBridgeKit
import BitwardenSdk
import CryptoKit
import Foundation

// MARK: - AuthenticatorSyncService

/// The service used to share TOTP codes to and from the Authenticator app.
///
protocol AuthenticatorSyncService {
    /// This starts the service listening for updates and writing to the shared store. This method
    /// must be called for the service to do any syncing.
    ///
    func start() async
}

// MARK: - DefaultAuthenticatorSyncService

/// The default `AuthenticatorSyncService` type for the application.
///
actor DefaultAuthenticatorSyncService: NSObject, AuthenticatorSyncService {
    // MARK: Private Properties

    /// The service for managing sharing items to/from the Authenticator app.
    private let authBridgeItemService: AuthenticatorBridgeItemService

    /// The Tasks listening for Cipher updates (one for each user, indexed by the userId).
    private var cipherPublisherTasks = [String: Task<Void, Error>?]()

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// Notification Center Service to subscribe to foreground/background events.
    private let notificationCenterService: NotificationCenterService

    /// The keychain repository for managing the key shared between the PM and Authenticator apps.
    private let sharedKeychainRepository: SharedKeychainRepository

    /// Whether or not the service has been started.
    private var started: Bool = false

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// a Task that subscribes to the sync setting publisher for accounts. This allows us to take action once
    /// a user opts-in to Authenticator sync.
    private var syncSettingSubscriberTask: Task<Void, Error>?

    /// The service used by the application to manage vault access.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultAuthenticatorSyncService`.
    ///
    /// - Parameters:
    ///   - authBridgeItemService: The service for managing sharing items to/from the Authenticator app.
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - configService: The service to get server-specified configuration.
    ///   - errorReporter: The service used by the application to report non-fatal errors.\ organizations.
    ///   - notificationCenterService: Notification Center Service to subscribe to foreground/background events.
    ///   - sharedKeychainRepository: The keychain repository for managing the key shared
    ///     between the PM and Authenticator apps.
    ///   - stateService: The service used by the application to manage account state.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        authBridgeItemService: AuthenticatorBridgeItemService,
        cipherService: CipherService,
        clientService: ClientService,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        notificationCenterService: NotificationCenterService,
        sharedKeychainRepository: SharedKeychainRepository,
        stateService: StateService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.authBridgeItemService = authBridgeItemService
        self.cipherService = cipherService
        self.clientService = clientService
        self.configService = configService
        self.errorReporter = errorReporter
        self.sharedKeychainRepository = sharedKeychainRepository
        self.notificationCenterService = notificationCenterService
        self.stateService = stateService
        self.vaultTimeoutService = vaultTimeoutService
        super.init()
    }

    // MARK: Public Methods

    public func start() async {
        guard !started else { return }
        started = true
        if await configService.getFeatureFlag(FeatureFlag.enableAuthenticatorSync,
                                              defaultValue: false) {
            subscribeToAppState()
        }
    }

    // MARK: Private Methods

    /// Check to see if the shared Authenticator key exists. If it doesn't already exist, create it.
    ///
    private func createAuthenticatorKeyIfNeeded() async throws {
        let storedKey = try? await sharedKeychainRepository.getAuthenticatorKey()
        if storedKey == nil {
            let key = SymmetricKey(size: .bits256)
            let data = key.withUnsafeBytes { Data(Array($0)) }
            try await sharedKeychainRepository.setAuthenticatorKey(data)
        }
    }

    /// Take a list of encrypted ciphers, decrypt them, filter for only active ciphers with a totp code, then
    /// convert the list to AuthenticatorSyncItemDataModel to be stored and sync'd to the Authenticator app.
    ///
    /// - Parameters:
    ///   - ciphers: The encrypted `Cipher` objects.
    ///   - userId: The userId of the account to which these Ciphers belong.
    ///
    /// - Returns: The decrypted, filtered, and sorted `CipherDTO` objects.
    ///
    private func decryptTOTPs(_ ciphers: [Cipher],
                              userId: String) async throws -> [AuthenticatorBridgeItemDataView] {
        let totpCiphers = ciphers.filter { cipher in
            cipher.deletedDate == nil
                && cipher.type == .login
                && cipher.login?.totp != nil
        }
        let decryptedCiphers = try await totpCiphers.asyncMap { cipher in
            try await self.clientService.vault().ciphers().decrypt(cipher: cipher)
        }
        let account = try await stateService.getActiveAccount()
        let username = account.profile.name ?? account.profile.email

        return decryptedCiphers.map { cipher in
            AuthenticatorBridgeItemDataView(
                favorite: false,
                id: cipher.id ?? UUID().uuidString,
                name: cipher.name,
                totpKey: cipher.login?.totp,
                username: username
            )
        }
    }

    /// This function handles the initial syncing with the Authenticator app as well as listening for updates
    /// when the user adds new items. This is called when the sync is turned on.
    ///
    /// - Parameter userId: The userId of the user who has turned on sync.
    ///
    private func handleSyncOnForUserId(_ userId: String) async {
        guard !vaultTimeoutService.isLocked(userId: userId) else {
            return
        }

        do {
            try await createAuthenticatorKeyIfNeeded()
        } catch {
            errorReporter.log(error: error)
        }
        subscribeToCipherUpdates(userId: userId)
    }

    /// This function handles stopping sync and cleaning up all sync-related items when a user has turned sync Off.
    ///
    /// - Parameter userId: The userId of the user who has turned off sync.
    ///
    private func handleSyncOffForUserId(_ userId: String) {
        cipherPublisherTasks[userId]??.cancel()
        cipherPublisherTasks[userId] = nil
    }

    /// Subscribe to NotificationCenter updates about if the app is in the foreground vs. background.
    ///
    private func subscribeToAppState() {
        Task {
            for await _ in notificationCenterService.willEnterForegroundPublisher() {
                subscribeToSyncToAuthenticatorSetting()
            }
        }
    }

    /// Create a task for the given userId to listen for Cipher updates and sync to the Authenticator store.
    ///
    /// - Parameter userId: The userId of the account to listen for.
    ///
    private func subscribeToCipherUpdates(userId: String) {
        guard cipherPublisherTasks[userId] == nil else { return }

        cipherPublisherTasks[userId] = Task {
            do {
                for try await ciphers in try await self.cipherService.ciphersPublisher().values {
                    try await writeCiphers(ciphers: ciphers, userId: userId)
                }
            } catch {
                errorReporter.log(error: error)
            }
        }
    }

    /// Subscribe to the Sync to Authenticator setting to handle when the user grants (or revokes)
    /// permission to sync items to the Authenticator app.
    ///
    private func subscribeToSyncToAuthenticatorSetting() {
        syncSettingSubscriberTask?.cancel()
        syncSettingSubscriberTask = Task {
            for await (userId, shouldSync) in await self.stateService.syncToAuthenticatorPublisher().values {
                guard let userId else { continue }

                if shouldSync {
                    await handleSyncOnForUserId(userId)
                } else {
                    handleSyncOffForUserId(userId)
                }
            }
        }
    }

    /// Takes in a list of encrypted Ciphers, decrypts them, and writes ones with TOTP codes to the shared store.
    ///
    /// - Parameters:
    ///   - ciphers: The array of Ciphers belonging to a user to decrypt and store if necessary.
    ///   - userId: The userId of the account to which the Ciphers belong.
    ///
    private func writeCiphers(ciphers: [Cipher], userId: String) async throws {
        let items = try await decryptTOTPs(ciphers, userId: userId)
        try await authBridgeItemService.replaceAllItems(with: items, forUserId: userId)
    }
}
