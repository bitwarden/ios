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

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultChangeKdfService`.
    ///
    /// - Parameters:
    ///   - accountAPIService: The services used by the application to make account related API requests.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - configService: The service to get server-specified configuration.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        accountAPIService: AccountAPIService,
        clientService: ClientService,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        stateService: StateService
    ) {
        self.accountAPIService = accountAPIService
        self.clientService = clientService
        self.configService = configService
        self.errorReporter = errorReporter
        self.stateService = stateService
    }

    // MARK: Methods

    func needsKdfUpdateToMinimums() async -> Bool {
        guard await configService.getFeatureFlag(.forceUpdateKdfSettings) else { return false }

        do {
            let account = try await stateService.getActiveAccount()
            guard account.kdf.kdfType == .pbkdf2sha256,
                  account.kdf.kdfIterations < Constants.minimumPbkdf2IterationsForUpgrade,
                  try await stateService.getUserHasMasterPassword(userId: account.profile.userId)
            else {
                return false
            }
            return true
        } catch {
            errorReporter.log(error: error)
            return false
        }
    }

    func updateKdfToMinimums(password: String) async throws {
        guard await configService.getFeatureFlag(.forceUpdateKdfSettings) else { return }

        let account = try await stateService.getActiveAccount()

        do {
            let updateKdfResponse = try await clientService.crypto().makeUpdateKdf(
                password: password,
                kdf: account.kdf.sdkKdf
            )
            try await accountAPIService.updateKdf(
                UpdateKdfRequestModel(response: updateKdfResponse)
            )
        } catch {
            // If an error occurs, log the error. Don't throw since that would block the vault unlocking.
            errorReporter.log(error: BitwardenError.generalError(
                type: "Force Update KDF Error",
                message: "Unable to update KDF settings (\(account.kdf)",
                error: error
            ))
        }
    }
}
