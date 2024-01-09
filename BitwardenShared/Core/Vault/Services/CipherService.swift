import BitwardenSdk
import Combine

// MARK: - CipherService

/// A protocol for a `CipherService` which manages syncing and updates to the user's ciphers.
///
protocol CipherService {
    /// A publisher for a user's cipher objects.
    ///
    /// - Parameter userId: The user ID of the user to associated with the objects to fetch.
    /// - Returns: A publisher for the user's ciphers.
    ///
    func cipherPublisher(userId: String) -> AnyPublisher<[Cipher], Error>

    /// Deletes a cipher for the current user both in the backend and in local storage..
    ///
    /// - Parameter id: The id of cipher item to be deleted.
    ///
    func deleteCipherWithServer(id: String) async throws

    /// Attempt to fetch a cipher with the given id.
    ///
    /// - Parameter id: The id of the cipher to find.
    /// - Returns: The cipher if it was found and `nil` if not.
    ///
    func fetchCipher(withId id: String) async throws -> Cipher?

    /// Replaces the persisted list of ciphers for the user.
    ///
    /// - Parameters:
    ///   - ciphers: The updated list of ciphers for the user.
    ///   - userId: The user ID associated with the ciphers.
    ///
    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws

    /// Shares a cipher with an organization and updates the locally stored data.
    ///
    /// - Parameter cipher: The cipher to share.
    ///
    func shareWithServer(_ cipher: Cipher) async throws

    /// soft deletes a cipher for the current user both in the backend and in local storage..
    ///
    /// - Parameter cipher: The  cipher item to be soft deleted.
    ///
    func softDeleteCipherWithServer(id: String, _ cipher: Cipher) async throws

    /// Updates the cipher's collections and updates the locally stored data.
    ///
    /// - Parameter cipher: The cipher to update.
    ///
    func updateCipherCollectionsWithServer(_ cipher: Cipher) async throws

    // MARK: Publishers

    /// A publisher for the list of ciphers.
    ///
    /// - Returns: The list of encrypted ciphers.
    ///
    func ciphersPublisher() async throws -> AnyPublisher<[Cipher], Error>
}

// MARK: - DefaultCipherService

class DefaultCipherService: CipherService {
    // MARK: Properties

    /// The service used to make cipher related API requests.
    let cipherAPIService: CipherAPIService

    /// The data store for managing the persisted ciphers for the user.
    let cipherDataStore: CipherDataStore

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultCipherService`.
    ///
    /// - Parameters:
    ///   - cipherAPIService: The service used to make cipher related API requests.
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
    func cipherPublisher(userId: String) -> AnyPublisher<[Cipher], Error> {
        cipherDataStore.cipherPublisher(userId: userId)
    }

    func deleteCipherWithServer(id: String) async throws {
        let userID = try await stateService.getActiveAccountId()

        // Delete cipher from backend.
        _ = try await cipherAPIService.deleteCipher(withID: id)

        // Delete cipher from local storage
        try await cipherDataStore.deleteCipher(id: id, userId: userID)
    }

    func fetchCipher(withId id: String) async throws -> Cipher? {
        let userId = try await stateService.getActiveAccountId()
        return try await cipherDataStore.fetchCipher(withId: id, userId: userId)
    }

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        try await cipherDataStore.replaceCiphers(ciphers.map(Cipher.init), userId: userId)
    }

    func shareWithServer(_ cipher: Cipher) async throws {
        let userId = try await stateService.getActiveAccountId()
        var response = try await cipherAPIService.shareCipher(cipher)
        response.collectionIds = cipher.collectionIds
        try await cipherDataStore.upsertCipher(Cipher(responseModel: response), userId: userId)
    }

    func softDeleteCipherWithServer(id: String, _ cipher: BitwardenSdk.Cipher) async throws {
        let userID = try await stateService.getActiveAccountId()

        // Soft delete cipher from backend.
        _ = try await cipherAPIService.softDeleteCipher(withID: id)

        // Soft delete cipher from local storage
        try await cipherDataStore.upsertCipher(cipher, userId: userID)
    }

    func updateCipherCollectionsWithServer(_ cipher: Cipher) async throws {
        let userId = try await stateService.getActiveAccountId()
        try await cipherAPIService.updateCipherCollections(cipher)
        try await cipherDataStore.upsertCipher(cipher, userId: userId)
    }

    // MARK: Publishers

    func ciphersPublisher() async throws -> AnyPublisher<[Cipher], Error> {
        let userID = try await stateService.getActiveAccountId()
        return cipherDataStore.cipherPublisher(userId: userID)
    }
}
