import BitwardenSdk

// MARK: - CipherService

/// A protocol for a `CipherService` which manages syncing and updates to the user's ciphers.
///
protocol CipherService {
    /// Replaces the persisted list of ciphers for the user.
    ///
    /// - Parameters:
    ///   - ciphers: The updated list of ciphers for the user.
    ///   - userId: The user ID associated with the ciphers.
    ///
    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws
}

// MARK: - DefaultCipherService

class DefaultCipherService: CipherService {
    // MARK: Properties

    /// The data store for managing the persisted ciphers for the user.
    let cipherDataStore: CipherDataStore

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultCipherService`.
    ///
    /// - Parameters:
    ///   - cipherDataStore: The data store for managing the persisted ciphers for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(cipherDataStore: CipherDataStore, stateService: StateService) {
        self.cipherDataStore = cipherDataStore
        self.stateService = stateService
    }
}

extension DefaultCipherService {
    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        try await cipherDataStore.replaceCiphers(ciphers.map(Cipher.init), userId: userId)
    }
}
