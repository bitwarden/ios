import BitwardenKit
import BitwardenSdk

/// `CipherRepository` implementation to be used on SDK client-managed state.
final class SdkCipherRepository: BitwardenSdk.CipherRepository {
    /// The data store for managing the persisted ciphers for the user.
    let cipherDataStore: CipherDataStore
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The user ID of the SDK instance this repository belongs to.
    let userId: String

    /// Initializes a `SdkCipherRepository`.
    /// - Parameters:
    ///   - cipherDataStore: The data store for managing the persisted ciphers for the user.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - userId: The user ID of the SDK instance this repository belongs to
    init(
        cipherDataStore: CipherDataStore,
        errorReporter: ErrorReporter,
        userId: String
    ) {
        self.cipherDataStore = cipherDataStore
        self.errorReporter = errorReporter
        self.userId = userId
    }

    func get(id: String) async throws -> BitwardenSdk.Cipher? {
        try await cipherDataStore.fetchCipher(withId: id, userId: userId)
    }

    func has(id: String) async throws -> Bool {
        let cipher = try await cipherDataStore.fetchCipher(withId: id, userId: userId)
        return cipher != nil
    }

    func list() async throws -> [BitwardenSdk.Cipher] {
        try await cipherDataStore.fetchAllCiphers(userId: userId)
    }

    func remove(id: String) async throws {
        try await cipherDataStore.deleteCipher(id: id, userId: userId)
    }

    func set(id: String, value: BitwardenSdk.Cipher) async throws {
        guard id == value.id else {
            throw BitwardenError.dataError("CipherRepository: Trying to update a cipher with mismatch IDs")
        }
        try await cipherDataStore.upsertCipher(value, userId: userId)
    }
}
