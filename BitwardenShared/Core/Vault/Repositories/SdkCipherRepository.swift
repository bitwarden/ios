import BitwardenKit
import BitwardenSdk

/// `CipherRepository` implementation to be used on SDK client-managed state.
final class SdkCipherRepository: BitwardenSdk.CipherRepository {
    /// The data store for managing the persisted ciphers for the user.
    let cipherDataStore: CipherDataStore
    /// The user ID of the SDK instance this repository belongs to.
    let userId: String

    /// Initializes a `SdkCipherRepository`.
    /// - Parameters:
    ///   - cipherDataStore: The data store for managing the persisted ciphers for the user.
    ///   - userId: The user ID of the SDK instance this repository belongs to
    init(
        cipherDataStore: CipherDataStore,
        userId: String,
    ) {
        self.cipherDataStore = cipherDataStore
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

    func removeAll() async throws {
        try await cipherDataStore.deleteAllCiphers(userId: userId)
    }

    func removeBulk(keys: [String]) async throws {
        // TODO: PM-35829
        for key in keys {
            try await cipherDataStore.deleteCipher(id: key, userId: userId)
        }
    }

    func set(id: String, value: BitwardenSdk.Cipher) async throws {
        guard id == value.id else {
            throw BitwardenError.dataError("CipherRepository: Trying to update a cipher with mismatch IDs")
        }
        try await cipherDataStore.upsertCipher(value, userId: userId)
    }

    func setBulk(values: [String: BitwardenSdk.Cipher]) async throws {
        // TODO: PM-35829
        for (id, cipher) in values {
            guard id == cipher.id else {
                throw BitwardenError.dataError("CipherRepository: Trying to update a cipher with mismatch IDs")
            }
        }
        for cipher in values.values {
            try await cipherDataStore.upsertCipher(cipher, userId: userId)
        }
    }
}
