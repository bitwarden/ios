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

    func listIter(batchSize: UInt32) throws -> BitwardenSdk.CipherIterator {
        SdkCipherIterator(
            batchSize: Int(max(batchSize, 1)),
            cipherDataStore: cipherDataStore,
            userId: userId,
        )
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

// MARK: - SdkCipherIterator

/// `CipherIterator` implementation that reads a user's ciphers from the data store a page at a
/// time, in order of their ID.
///
/// Each call to `next()` fetches the page after the ID of the last cipher read, so only the
/// current page is held in memory. The data store performs each fetch on its managed object
/// context's queue, so `next()` can be called from any thread.
///
actor SdkCipherIterator: BitwardenSdk.CipherIterator {
    // MARK: Properties

    /// The maximum number of ciphers in each page.
    private let batchSize: Int

    /// The data store for managing the persisted ciphers for the user.
    private let cipherDataStore: CipherDataStore

    /// Whether every cipher has been read.
    private var isFinished = false

    /// The ID of the last cipher read, or `nil` before the first page.
    private var lastId: String?

    /// The user ID whose ciphers are read.
    private let userId: String

    // MARK: Initialization

    /// Initializes a `SdkCipherIterator`.
    ///
    /// - Parameters:
    ///   - batchSize: The maximum number of ciphers in each page.
    ///   - cipherDataStore: The data store for managing the persisted ciphers for the user.
    ///   - userId: The user ID whose ciphers are read.
    ///
    init(batchSize: Int, cipherDataStore: CipherDataStore, userId: String) {
        self.batchSize = batchSize
        self.cipherDataStore = cipherDataStore
        self.userId = userId
    }

    // MARK: CipherIterator

    func next() async throws -> [BitwardenSdk.Cipher]? {
        guard !isFinished else { return nil }

        let page = try await cipherDataStore.fetchCiphers(userId: userId, afterId: lastId, limit: batchSize)
        // A short page is the last one. A page that ends with a cipher without an ID also ends the
        // listing, as there is no ID for the next page to start after.
        guard page.count == batchSize, let lastId = page.last?.id else {
            isFinished = true
            return page.isEmpty ? nil : page
        }
        self.lastId = lastId
        return page
    }
}
