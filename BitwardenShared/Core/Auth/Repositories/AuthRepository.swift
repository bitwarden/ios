import BitwardenSdk

/// A protocol for an `AuthRepository` which manages access to the data needed by the UI layer.
///
protocol AuthRepository: AnyObject {
    // MARK: Methods

    /// Logs the user out of the active account.
    ///
    func logout() async throws

    /// Attempts to unlock the user's vault with their master password.
    ///
    /// - Parameter password: The user's master password to unlock the vault.
    ///
    func unlockVault(password: String) async throws
}

// MARK: - DefaultAuthRepository

/// A default implementation of an `AuthRepository`.
///
class DefaultAuthRepository {
    // MARK: Properties

    /// The client used by the application to handle encryption and decryption setup tasks.
    let clientCrypto: ClientCryptoProtocol

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultAuthRepository`.
    ///
    /// - Parameters:
    ///   - clientCrypto: The client used by the application to handle encryption and decryption setup tasks.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        clientCrypto: ClientCryptoProtocol,
        stateService: StateService
    ) {
        self.clientCrypto = clientCrypto
        self.stateService = stateService
    }
}

// MARK: - AuthRepository

extension DefaultAuthRepository: AuthRepository {
    func logout() async throws {
        try await stateService.logoutAccount()
    }

    func unlockVault(password: String) async throws {
        let encryptionKeys = try await stateService.getAccountEncryptionKeys()
        let account = try await stateService.getActiveAccount()
        let kdf = KdfConfig(
            kdf: account.profile.kdfType ?? .pbkdf2sha256,
            kdfIterations: account.profile.kdfIterations ?? Constants.pbkdf2Iterations,
            kdfMemory: account.profile.kdfMemory,
            kdfParallelism: account.profile.kdfParallelism
        )
        try await clientCrypto.initializeCrypto(
            req: InitCryptoRequest(
                kdfParams: kdf.sdkKdf,
                email: account.profile.email,
                password: password,
                userKey: encryptionKeys.encryptedUserKey,
                privateKey: encryptionKeys.encryptedPrivateKey,
                organizationKeys: [:]
            )
        )
    }
}
