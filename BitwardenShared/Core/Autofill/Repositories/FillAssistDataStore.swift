import BitwardenKit
import CryptoKit
import Foundation

// MARK: - FillAssistDataStore

/// A protocol for a store that persists fill-assist cached data encrypted on disk.
///
protocol FillAssistDataStore { // sourcery: AutoMockable
    /// Loads the cached fill-assist data for a user.
    ///
    /// - Parameter userId: The user ID whose data to load.
    /// - Returns: The cached `FillAssistCachedData`, or `nil` if none is stored.
    ///
    func load(userId: String) async throws -> FillAssistCachedData?

    /// Saves fill-assist cached data for a user, encrypting it before writing to disk.
    ///
    /// - Parameters:
    ///   - data: The `FillAssistCachedData` to persist.
    ///   - userId: The user ID to associate the data with.
    ///
    func save(_ data: FillAssistCachedData, userId: String) async throws

    /// Deletes the cached fill-assist data and encryption key for a user.
    ///
    /// - Parameter userId: The user ID whose data and key to delete.
    ///
    func delete(userId: String) async throws
}

// MARK: - DefaultFillAssistDataStore

/// The default implementation of `FillAssistDataStore`.
///
/// Data is AES-GCM encrypted with a per-user 256-bit key stored in the Keychain,
/// and written to `{applicationSupportDirectory}/FillAssistRules/{userId}.bin` with
/// `.completeUntilFirstUserAuthentication` file protection.
///
class DefaultFillAssistDataStore: FillAssistDataStore {
    // MARK: Properties

    /// The file manager used for file I/O.
    private let fileManager: FileManager

    /// The Keychain repository for storing and retrieving the encryption key.
    private let keychainRepository: KeychainRepository

    /// An optional directory override used in tests to avoid writing to the real app container.
    private let overrideBaseURL: URL?

    // MARK: Initialization

    /// Creates a `DefaultFillAssistDataStore`.
    ///
    /// - Parameters:
    ///   - fileManager: The file manager to use for file I/O. Defaults to `.default`.
    ///   - keychainRepository: The Keychain repository for key storage.
    ///   - overrideBaseURL: Base directory override for tests. Production callers omit this.
    ///
    init(
        fileManager: FileManager = .default,
        keychainRepository: KeychainRepository,
        overrideBaseURL: URL? = nil,
    ) {
        self.fileManager = fileManager
        self.keychainRepository = keychainRepository
        self.overrideBaseURL = overrideBaseURL
    }

    // MARK: FillAssistDataStore

    func load(userId: String) async throws -> FillAssistCachedData? {
        let fileURL = try rulesFileURL(for: userId)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let key = try await encryptionKey(for: userId)
        let combined = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let plaintext = try AES.GCM.open(sealedBox, using: key)
        return try JSONDecoder().decode(FillAssistCachedData.self, from: plaintext)
    }

    func save(_ data: FillAssistCachedData, userId: String) async throws {
        let fileURL = try rulesFileURL(for: userId)
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        let key = try await encryptionKey(for: userId)
        let plaintext = try JSONEncoder().encode(data)
        let sealedBox = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealedBox.combined else {
            throw FillAssistDataStoreError.encryptionFailed
        }
        try combined.write(to: fileURL, options: .completeFileProtectionUntilFirstUserAuthentication)
    }

    func delete(userId: String) async throws {
        let fileURL = try rulesFileURL(for: userId)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        try await keychainRepository.deleteUserAuthKey(for: .fillAssistEncryptionKey(userId: userId))
    }

    // MARK: Private

    private func rulesFileURL(for userId: String) throws -> URL {
        if let base = overrideBaseURL {
            return base.appendingPathComponent("\(userId).bin")
        }
        return try fileManager.fillAssistRulesURL(for: userId)
    }

    /// Returns the AES-256 encryption key for a user, creating and storing it if it does not exist.
    ///
    /// Propagates any Keychain error (e.g. locked device) so callers can retry rather than
    /// silently generating a new key and making existing encrypted data permanently unreadable.
    ///
    private func encryptionKey(for userId: String) async throws -> SymmetricKey {
        do {
            let stored = try await keychainRepository.getUserAuthKeyValue(
                for: .fillAssistEncryptionKey(userId: userId),
            )
            if let key = SymmetricKey(base64EncodedString: stored) {
                return key
            }
        } catch KeychainServiceError.keyNotFound {
            // Key genuinely absent — fall through to generate a new one.
        }
        // stored == nil or key was not found: generate, persist, and return a fresh key.
        let key = SymmetricKey(size: .bits256)
        try await keychainRepository.setUserAuthKey(
            for: .fillAssistEncryptionKey(userId: userId),
            value: key.base64EncodedString(),
        )
        return key
    }
}

// MARK: - FillAssistDataStoreError

enum FillAssistDataStoreError: Error {
    case encryptionFailed
}

// MARK: - SymmetricKey + Base64

private extension SymmetricKey {
    init?(base64EncodedString: String) {
        guard let data = Data(base64Encoded: base64EncodedString) else { return nil }
        self.init(data: data)
    }

    func base64EncodedString() -> String {
        withUnsafeBytes { Data($0).base64EncodedString() }
    }
}
