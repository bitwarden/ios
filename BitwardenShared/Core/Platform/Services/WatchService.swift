import BitwardenSdk
import Combine
import WatchConnectivity

// MARK: - WatchService

/// The service used to connect to and communicate with the watch app.
///
protocol WatchService {}

// MARK: - DefaultWatchService

/// The default `WatchService` type for the application.
///
class DefaultWatchService: NSObject, WatchService {
    // MARK: Private Properties

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The client used by the application to handle vault encryption and decryption tasks.
    private let clientVault: ClientVaultService

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to manage syncing and updates to the user's organizations.
    private let organizationService: OrganizationService

    /// The watch connect session.
    private var session: WCSession?

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// Keep a reference to the task used to sync the watch when the ciphers change, so that
    /// it can be cancelled and recreated when the user changes.
    private var syncCiphersTask: Task<Void, Never>?

    // MARK: Initialization

    /// Initialize a `DefaultWatchService`.
    ///
    /// - Parameters:
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientVault: The client used by the application to handle vault encryption and decryption tasks.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - organizationService: The service used to manage syncing and updates to the user's organizations.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        cipherService: CipherService,
        clientVault: ClientVaultService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        organizationService: OrganizationService,
        stateService: StateService
    ) {
        self.cipherService = cipherService
        self.clientVault = clientVault
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.organizationService = organizationService
        self.stateService = stateService
        super.init()

        // Listen for changes in the settings and data that would require syncing with the watch.
        Task {
            let jointPublisher = await Publishers.CombineLatest(
                self.stateService.activeAccountIdPublisher(),
                self.stateService.connectToWatchPublisher()
            )
            .values

            for await values in jointPublisher {
                syncWithWatch(userId: values.0, shouldConnect: values.1)
            }
        }
    }

    // MARK: Private Methods

    /// Take a list of encrypted ciphers, decrypt them, filter for only active ciphers with a totp code, then
    /// convert the list to the simple cipher objects used to communicate with the watch.
    ///
    /// - Parameter ciphers: The encrypted `Cipher` objects.
    ///
    /// - Returns: The decrypted, filtered, and sorted `CipherDTO` objects.
    ///
    private func decryptCiphers(_ ciphers: [Cipher]) async throws -> [CipherDTO] {
        let decryptedCiphers = try await ciphers.asyncMap { cipher in
            try await self.clientVault.ciphers().decrypt(cipher: cipher)
        }

        return decryptedCiphers.filter { cipher in
            cipher.deletedDate == nil
                && cipher.type == .login
                && cipher.login?.totp != nil
        }
        .compactMap { CipherDTO(cipherView: $0) }
    }

    /// Load the active account, if one exists, and determine if it is accurately set up to connect to the watch.
    ///
    /// - Parameter shouldConnect: Whether the user has toggled on the connect to watch setting.
    ///
    /// - Returns: The user data or the invalid state to sync to the watch.
    ///
    private func getUserData(_ shouldConnect: Bool) async -> (user: UserDTO?, state: BWState) {
        // Get the user's account information.
        let account = try? await stateService.getActiveAccount()
        guard let account else {
            return (nil, .needLogin)
        }
        let userData = UserDTO(
            email: account.profile.email,
            id: account.profile.userId,
            name: account.profile.name
        )

        // If the user isn't set up to use the watch, sync the invalid state to the watch.
        guard shouldConnect else { return (nil, .needSetup) }

        // Ensure the user has access to premium features or sync the invalid state to the watch.
        if account.profile.hasPremiumPersonally != true {
            let organizations = try? await organizationService
                .fetchAllOrganizations()
                .filter { $0.enabled && $0.usersGetPremium }
            guard organizations?.isEmpty == false else { return (nil, .needPremium) }
        }

        // Return the user data with the valid state.
        return (userData, .valid)
    }

    /// Handle messages received from the watch to listen for requests to sync.
    ///
    /// - Parameter message: The message received from the watch.
    ///
    private func handleMessage(_ message: [String: Any]) {
        if let actionMessage = message["actionMessage"] as? String,
           actionMessage == "triggerSync" {
            Task {
                let userId = try? await self.stateService.getActiveAccountId()
                let shouldConnect = try? await self.stateService.getConnectToWatch()
                let lastUserShouldConnectToWatch = await self.stateService.getLastUserShouldConnectToWatch()
                syncWithWatch(userId: userId, shouldConnect: shouldConnect ?? lastUserShouldConnectToWatch)
            }
        }
    }

    /// Start the session to connect to the watch.
    private func startSession() {
        if WCSession.isSupported(), session == nil {
            session = WCSession.default
            session?.delegate = self
        }
        if session?.activationState != .activated {
            session?.activate()
        }
    }

    /// Sync data with the watch.
    ///
    /// - Parameters:
    ///   - ciphers: All the ciphers for the current user, or an empty list otherwise.
    ///   - shouldConnect: Whether the user has toggled on the connect to watch setting.
    ///
    private func syncWithWatch(ciphers: [Cipher], shouldConnect: Bool) async throws {
        guard WCSession.isSupported() else { return }

        // Connect the session if necessary.
        if shouldConnect, session?.activationState != .activated {
            startSession()
        }
        guard let session, session.isPaired, session.isWatchAppInstalled else { return }

        // Get the user information.
        let userResult = await getUserData(shouldConnect)
        guard let userData = userResult.user else {
            return try session.sendInvalidState(userResult.state)
        }

        // Decrypt and filter the ciphers.
        let activeCiphers = try await decryptCiphers(ciphers)

        // If there are no active totp ciphers, send the status to the watch.
        if activeCiphers.isEmpty {
            return try session.sendInvalidState(.need2FAItem)
        }

        // Send the resulting data to the watch.
        let watchData = WatchDTO(
            state: .valid,
            ciphers: activeCiphers,
            userData: userData,
            environmentData: .init(
                base: environmentService.apiURL.absoluteString,
                icons: environmentService.iconsURL.absoluteString
            )
        )
        try session.sendDataToWatch(watchData)
    }

    /// Fetch the ciphers for the user, if logged in, and sync with the watch.
    ///
    /// - Parameters:
    ///   - userId: The user's id, if one exists.
    ///   - shouldConnect: Whether the user has toggled on the connect to watch setting.
    ///
    private func syncWithWatch(userId: String?, shouldConnect: Bool) {
        // This method will be called whenever the connect value or the account value changes,
        // so the task listening to the cipher updates will need to be cancelled and recreated
        // each time.
        syncCiphersTask?.cancel()
        syncCiphersTask = Task {
            do {
                // If the user isn't logged in, sync the watch with an empty list of ciphers.
                guard userId != nil else {
                    try await syncWithWatch(ciphers: [], shouldConnect: shouldConnect)
                    return
                }

                // Otherwise, listen to the publisher to sync any cipher updates with the watch.
                for try await ciphers in try await cipherService.ciphersPublisher().values {
                    try await syncWithWatch(ciphers: ciphers, shouldConnect: shouldConnect)
                }
            } catch {
                self.errorReporter.log(error: error)
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension DefaultWatchService: WCSessionDelegate {
    /// Required delegate method that requires no action on the app.
    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}

    /// Required delegate method that requires no action on the app.
    func sessionDidBecomeInactive(_: WCSession) {}

    /// Required delegate method that requires no action on the app.
    func sessionDidDeactivate(_: WCSession) {}

    /// Handle messages received from the watch.
    func session(_: WCSession, didReceiveMessage message: [String: Any]) {
        handleMessage(message)
    }

    /// Handle messages received from the watch.
    func session(
        _: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler _: @escaping ([String: Any]) -> Void
    ) {
        handleMessage(message)
    }
}

// MARK: - WCSession

extension WCSession {
    /// A convenience method for supreme laziness to send a state to the watch.
    ///
    /// - Parameter state: The invalid state to send.
    ///
    func sendInvalidState(_ state: BWState) throws {
        try sendDataToWatch(WatchDTO(state: state))
    }

    /// Encode the data and send it to the watch.
    ///
    /// - Parameter watchData: The data to send to the watch.
    ///
    func sendDataToWatch(_ watchData: WatchDTO) throws {
        let data = try MessagePackEncoder().encode(watchData)
        let compressedData = try NSData(data: data).compressed(using: .lzfse)

        // Add time to the key to make it change on every message sent so that it's delivered faster.
        let dictionary = ["watchDto-\(Date())": compressedData]
        try updateApplicationContext(dictionary)
    }
}

// MARK: - CipherDTO

extension CipherDTO {
    /// Initialize a simplified cipher model from a regular cipher view.
    ///
    /// - Parameter cipherView: The cipher view to use.
    ///
    init?(cipherView: CipherView) {
        guard let id = cipherView.id else { return nil }
        self.init(
            id: id,
            login: .init(
                totp: cipherView.login?.totp,
                uris: cipherView.login?.uris?.compactMap { .init(uri: $0.uri) },
                username: cipherView.login?.username
            ),
            name: cipherView.name
        )
    }
}
