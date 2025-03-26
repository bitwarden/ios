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

    /// Gets a temporary TOTP item that was saved from the Authenticator app. If no code was found or any
    /// errors occur, it simply returns `nil`
    ///
    /// - Returns: An `AuthenticatorBridgeItemDataView` representing the saved item or
    ///     `nil` if a temporary item couldn't be found.
    ///
    func getTemporaryTotpItem() async -> AuthenticatorBridgeItemDataView?
}

// MARK: - DefaultAuthenticatorSyncService

/// The default `AuthenticatorSyncService` type for the application.
///
actor DefaultAuthenticatorSyncService: NSObject, AuthenticatorSyncService {
    // MARK: Private Properties

    /// The service for managing sharing items to/from the Authenticator app.
    private let authBridgeItemService: AuthenticatorBridgeItemService

    /// AuthRepository for unlocking the vault with the Authenticator Key.
    private let authRepository: AuthRepository

    /// The Tasks listening for Cipher updates (one for each user, indexed by the userId).
    private var cipherPublisherTasks = [String: Task<Void, Error>]()

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherDataStore: CipherDataStore

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

    /// A task that sets up syncing for a user.
    ///
    /// Using an actor-protected `Task` ensures that multiple threads don't attempt
    /// to setup sync at the same time. `enableSyncForUserId(_)` `await`s
    /// the result of this task before adding the next sync setup to the end of it.
    private var enableSyncTask: Task<Void, Never>?

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// Keychain Repository for storing/accessing the Authenticator Vault Key.
    private let keychainRepository: KeychainRepository

    /// The keychain repository for managing the key shared between the PM and Authenticator apps.
    private let sharedKeychainRepository: SharedKeychainRepository

    /// Whether or not the service has been started.
    private var started: Bool = false

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// A Task to hold the subscription that waits for sync to be turned on/off.
    private var syncSubscriber: Task<Void, Never>?

    /// A Task to hold the subscription that waits for the vault to be locked/unlocked.
    private var vaultSubscriber: Task<Void, Never>?

    /// The service used by the application to manage vault access.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultAuthenticatorSyncService`.
    ///
    /// - Parameters:
    ///   - authBridgeItemService: The service for managing sharing items to/from the Authenticator app.
    ///   - authRepository: AuthRepository for unlocking the vault with the Authenticator Key.
    ///   - cipherDataStore: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - configService: The service to get server-specified configuration.
    ///   - errorReporter: The service used by the application to report non-fatal errors.\ organizations.
    ///   - keychainRepository: Keychain Repository for storing/accessing the Authenticator Vault Key.
    ///   - sharedKeychainRepository: The keychain repository for managing the key shared
    ///     between the PM and Authenticator apps.
    ///   - stateService: The service used by the application to manage account state.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        authBridgeItemService: AuthenticatorBridgeItemService,
        authRepository: AuthRepository,
        cipherDataStore: CipherDataStore,
        clientService: ClientService,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        keychainRepository: KeychainRepository,
        sharedKeychainRepository: SharedKeychainRepository,
        stateService: StateService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.authBridgeItemService = authBridgeItemService
        self.authRepository = authRepository
        self.cipherDataStore = cipherDataStore
        self.clientService = clientService
        self.configService = configService
        self.errorReporter = errorReporter
        self.keychainRepository = keychainRepository
        self.sharedKeychainRepository = sharedKeychainRepository
        self.stateService = stateService
        self.vaultTimeoutService = vaultTimeoutService
        super.init()
    }

    deinit {
        syncSubscriber?.cancel()
        vaultSubscriber?.cancel()
    }

    // MARK: Public Methods

    public func getTemporaryTotpItem() async -> AuthenticatorBridgeItemDataView? {
        guard await configService.getFeatureFlag(FeatureFlag.enableAuthenticatorSync) else {
            return nil
        }
        do {
            return try await authBridgeItemService.fetchTemporaryItem()
        } catch {
            errorReporter.log(error: error)
            return nil
        }
    }

    public func start() async {
        guard !started else { return }
        started = true

        syncSubscriber = Task {
            for await (userId, _) in await self.stateService.syncToAuthenticatorPublisher().values {
                guard let userId else { continue }

                do {
                    try await determineSyncForUserId(userId)
                } catch {
                    errorReporter.log(error: error)
                }
            }
        }
        vaultSubscriber = Task {
            for await vaultStatus in await self.vaultTimeoutService.vaultLockStatusPublisher().values {
                guard let vaultStatus else { continue }

                do {
                    try await determineSyncForUserId(vaultStatus.userId)
                } catch {
                    errorReporter.log(error: error)
                }
            }
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

    /// Store the user's vault key in the keychain so we can unlock that vault for them when ciphers are received.
    ///
    /// Note: The userId must be the active account or else this function will return without setting up the key.
    ///
    /// - Parameter userId: The userId of the account whose vault unlock is being set up.
    ///
    private func createAuthenticatorVaultKeyIfNeeded(userId: String) async throws {
        let authVaultKey = try? await keychainRepository.getAuthenticatorVaultKey(userId: userId)
        guard authVaultKey == nil,
              let activeId = try? await stateService.getActiveAccountId(),
              activeId == userId else { return }

        let key = try await clientService.crypto().getUserEncryptionKey()
        try await keychainRepository.setAuthenticatorVaultKey(key, userId: userId)
    }

    /// Take a list of encrypted ciphers, filter for only active ciphers with a totp code,  decrypt them, then
    /// convert the list to AuthenticatorSyncItemDataView to be stored and sync'd to the Authenticator app.
    ///
    /// - Parameters:
    ///   - ciphers: The encrypted `Cipher` objects.
    ///   - account: The account to which these Ciphers belong.
    ///
    /// - Returns: The decrypted, filtered, and sorted `CipherDTO` objects.
    ///
    private func decryptTOTPs(_ ciphers: [Cipher],
                              account: Account) async throws -> [AuthenticatorBridgeItemDataView] {
        let totpCiphers = ciphers.filter { cipher in
            cipher.deletedDate == nil
                && cipher.type == .login
                && cipher.login?.totp != nil
        }
        let decryptedCiphers = try await totpCiphers.asyncMap { cipher in
            try await self.clientService.vault(for: account.profile.userId).ciphers().decrypt(cipher: cipher)
        }

        return decryptedCiphers.map { cipher in
            AuthenticatorBridgeItemDataView(
                accountDomain: account.settings.environmentUrls?.webVaultHost ?? Constants.defaultWebVaultHost,
                accountEmail: account.profile.email,
                favorite: false,
                id: cipher.id ?? UUID().uuidString,
                name: cipher.name,
                totpKey: cipher.login?.totp,
                username: cipher.login?.username
            )
        }
    }

    /// If sync has been turned off for all accounts, delete the Authenticator key from the shared keychain.
    ///
    private func deleteKeyIfSyncingIsOff() async throws {
        for account in try await stateService.getAccounts() {
            let hasAccountWithSync = try await stateService.getSyncToAuthenticator(userId: account.profile.userId)
            guard !hasAccountWithSync else {
                return
            }
        }
        try sharedKeychainRepository.deleteAuthenticatorKey()
    }

    /// Determine if the given userId has sync turned on and an unlocked vault. This method serves as the
    /// integration point of both the sync settings subscriber and the vault subscriber. When the user has sync turned
    /// on and the vault unlocked, we can proceed with the sync.
    ///
    /// - Parameter userId: The userId of the user whose sync status is being determined.
    ///
    private func determineSyncForUserId(_ userId: String) async throws {
        guard
            await configService.getFeatureFlag(
                FeatureFlag.enableAuthenticatorSync,
                defaultValue: false
            )
        else { return }

        if try await stateService.getSyncToAuthenticator(userId: userId) {
            enableSyncForUserId(userId)
        } else {
            cipherPublisherTasks[userId]?.cancel()
            cipherPublisherTasks.removeValue(forKey: userId)
            try await keychainRepository.deleteAuthenticatorVaultKey(userId: userId)
            try await authBridgeItemService.deleteAllForUserId(userId)
            try await deleteKeyIfSyncingIsOff()
        }
    }

    /// Enable sync for the provided userId.
    ///
    /// - Parameter userId: The userId of the user whose sync is being enabled.
    ///
    private func enableSyncForUserId(_ userId: String) {
        enableSyncTask = Task { [enableSyncTask] in
            _ = await enableSyncTask?.result

            do {
                guard !vaultTimeoutService.isLocked(userId: userId) else {
                    let authVaultKey = try? await keychainRepository.getAuthenticatorVaultKey(userId: userId)
                    if authVaultKey != nil {
                        subscribeToCipherUpdates(userId: userId)
                    }
                    return
                }

                try await createAuthenticatorKeyIfNeeded()
                try await createAuthenticatorVaultKeyIfNeeded(userId: userId)
                subscribeToCipherUpdates(userId: userId)
            } catch {
                errorReporter.log(error: error)
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
                for try await ciphers in self.cipherDataStore.cipherPublisher(userId: userId).values {
                    try await writeCiphers(ciphers: ciphers, userId: userId)
                }
            } catch {
                errorReporter.log(error: error)
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
        let account = try await stateService.getAccount(userId: userId)
        let useKey = vaultTimeoutService.isLocked(userId: userId)

        do {
            if useKey {
                try await authRepository.unlockVaultWithAuthenticatorVaultKey(userId: userId)
            }
            let items = try await decryptTOTPs(ciphers, account: account)
            try await authBridgeItemService.replaceAllItems(with: items, forUserId: userId)
        } catch {
            errorReporter.log(error: error)
        }
        if useKey {
            await vaultTimeoutService.lockVault(userId: userId)
        }
    }
}
