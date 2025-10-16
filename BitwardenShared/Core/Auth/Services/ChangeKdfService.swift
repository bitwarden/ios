import BitwardenKit

// MARK: - ChangeKdfService

/// A protocol for a `ChangeKdfService` which handles updating the KDF settings for a user.
///
protocol ChangeKdfService {
    /// Returns whether the user needs to update their KDF settings to the minimum.
    ///
    /// - Returns: Whether the user needs to update their KDF settings to the minimum.
    ///
    func needsKdfUpdateToMinimums() async -> Bool

    /// Updates the user's KDF settings to the minimums.
    ///
    /// - Parameter password: The user's master password.
    ///
    func updateKdfToMinimums(password: String) async throws
}

extension ChangeKdfService {
    /// Updates the user's KDF settings to the minimums if their current settings are below the minimums.
    ///
    /// - Parameter password: The user's master password.
    ///
    func updateKdfToMinimumsIfNeeded(password: String) async throws {
        guard await needsKdfUpdateToMinimums() else { return }
        try await updateKdfToMinimums(password: password)
    }
}

// MARK: - DefaultChangeKdfService

/// A default implementation of a `ChangeKdfService`.
///
class DefaultChangeKdfService: ChangeKdfService {
    // MARK: Properties

    /// The services used by the application to make account related API requests.
    private let accountAPIService: AccountAPIService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used by the application for recording temporary debug logs.
    private let flightRecorder: FlightRecorder

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    private let syncService: SyncService

    // MARK: Initialization

    /// Initialize a `DefaultChangeKdfService`.
    ///
    /// - Parameters:
    ///   - accountAPIService: The services used by the application to make account related API requests.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - configService: The service to get server-specified configuration.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///
    init(
        accountAPIService: AccountAPIService,
        clientService: ClientService,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        flightRecorder: FlightRecorder,
        stateService: StateService,
        syncService: SyncService,
    ) {
        self.accountAPIService = accountAPIService
        self.clientService = clientService
        self.configService = configService
        self.errorReporter = errorReporter
        self.flightRecorder = flightRecorder
        self.stateService = stateService
        self.syncService = syncService
    }

    // MARK: Methods

    func needsKdfUpdateToMinimums() async -> Bool {
        guard await configService.getFeatureFlag(.forceUpdateKdfSettings) else { return false }

        do {
            guard try await accountNeedsKdfUpdate() else { return false }

            // If the account needs a KDF update, sync the user's account and check again before
            // proceeding to ensure the local data is up-to-date.
            try await syncService.fetchSync(forceSync: false)
            return try await accountNeedsKdfUpdate()
        } catch {
            errorReporter.log(error: error)
            return false
        }
    }

    func updateKdfToMinimums(password: String) async throws {
        guard await configService.getFeatureFlag(.forceUpdateKdfSettings) else { return }

        let account = try await stateService.getActiveAccount()

        do {
            let kdfConfig = KdfConfig.defaultKdfConfig
            let updateKdfResponse = try await clientService.crypto().makeUpdateKdf(
                password: password,
                kdf: kdfConfig.sdkKdf,
            )
            try await accountAPIService.updateKdf(
                UpdateKdfRequestModel(response: updateKdfResponse),
            )
            try await stateService.setAccountKdf(kdfConfig, userId: account.profile.userId)
            await flightRecorder.log("[Auth] Upgraded user's KDF to minimums")
        } catch {
            errorReporter.log(error: BitwardenError.generalError(
                type: "Force Update KDF Error",
                message: "Unable to update KDF settings (\(account.kdf)",
                error: error,
            ))
            throw error
        }
    }

    // MARK: Private

    /// Returns whether the active account needs to update their KDF to meet the minimum requirements.
    ///
    /// - Returns: Whether the active account needs a KDF update.
    ///
    private func accountNeedsKdfUpdate() async throws -> Bool {
        let account = try await stateService.getActiveAccount()
        guard account.kdf.kdfType == .pbkdf2sha256,
              account.kdf.kdfIterations < Constants.minimumPbkdf2IterationsForUpgrade,
              try await stateService.getUserHasMasterPassword(userId: account.profile.userId)
        else {
            return false
        }
        return true
    }
}
