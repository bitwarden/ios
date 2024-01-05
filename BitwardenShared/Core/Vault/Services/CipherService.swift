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
    func cipherPublisher(userId: String) -> AnyPublisher<[Cipher], Error> {
        cipherDataStore.cipherPublisher(userId: userId)
    }

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        try await cipherDataStore.replaceCiphers(ciphers.map(Cipher.init), userId: userId)
    }
}
