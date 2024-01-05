import BitwardenSdk

// MARK: - CipherService

/// A protocol for a `CipherService` which manages syncing and updates to the user's ciphers.
///
protocol CipherService {
    /// Deletes a cipher for the current user both in the backend and in local storage..
    ///
    /// - Parameter id: The id of cipher item to be deleted.
    ///
    func deleteCipherWithServer(id: String) async throws

    /// Replaces the persisted list of ciphers for the user.
    ///
    /// - Parameters:
    ///   - ciphers: The updated list of ciphers for the user.
    ///   - userId: The user ID associated with the ciphers.
    ///
    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws

    /// soft deletes a cipher for the current user both in the backend and in local storage..
    ///
    /// - Parameter cipher: The  cipher item to be soft deleted.
    ///
    func softDeleteCipherWithServer(id: String, _ cipher: Cipher) async throws
}

// MARK: - DefaultCipherService

class DefaultCipherService: CipherService {
    // MARK: Properties

    /// The data store for managing the persisted ciphers for the user.
    let cipherAPIService: CipherAPIService

    /// The data store for managing the persisted ciphers for the user.
    let cipherDataStore: CipherDataStore

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultCipherService`.
    ///
    /// - Parameters:
    ///   - cipherAPIService: The API service used to perform API requests for the ciphers in a user's vault.
    ///   - cipherDataStore: The data store for managing the persisted ciphers for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        cipherAPIService: CipherAPIService,
        cipherDataStore: CipherDataStore,
        stateService: StateService
    ) {
        self.cipherAPIService = cipherAPIService
        self.cipherDataStore = cipherDataStore
        self.stateService = stateService
    }
}

extension DefaultCipherService {
    func deleteCipherWithServer(id: String) async throws {
        let userID = try await stateService.getActiveAccountId()

        // Delete cipher from backend.
        _ = try await cipherAPIService.deleteCipher(withID: id)

        // Delete cipher from local storage
        try await cipherDataStore.deleteCipher(id: id, userId: userID)
    }

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        try await cipherDataStore.replaceCiphers(ciphers.map(Cipher.init), userId: userId)
    }

    func softDeleteCipherWithServer(id: String, _ cipher: Cipher) async throws {
        let userID = try await stateService.getActiveAccountId()

        // Soft delete cipher from backend.
        _ = try await cipherAPIService.softDeleteCipher(withID: id)

        // Soft delete cipher from local storage
        try await cipherDataStore.upsertCipher(cipher, userId: userID)
    }
}
