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

    // MARK: Initialization

    /// Creates a `DefaultFillAssistDataStore`.
    ///
    /// - Parameters:
    ///   - fileManager: The file manager to use for file I/O. Defaults to `.default`.
    ///   - keychainRepository: The Keychain repository for key storage.
    ///
    init(
        fileManager: FileManager = .default,
        keychainRepository: KeychainRepository,
    ) {
        self.fileManager = fileManager
        self.keychainRepository = keychainRepository
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
        try? await keychainRepository.deleteUserAuthKey(for: .fillAssistEncryptionKey(userId: userId))
    }

    // MARK: Private

    /// Returns the file URL for a user's encrypted rules file.
    ///
    private func rulesFileURL(for userId: String) throws -> URL {
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw FillAssistDataStoreError.missingApplicationSupportDirectory
        }
        return base
            .appendingPathComponent("FillAssistRules", isDirectory: true)
            .appendingPathComponent("\(userId).bin")
    }

    /// Returns the AES-256 encryption key for a user, creating and storing it if it does not exist.
    ///
    private func encryptionKey(for userId: String) async throws -> SymmetricKey {
        if let stored = try? await keychainRepository.getUserAuthKeyValue(
            for: .fillAssistEncryptionKey(userId: userId)
        ), let key = SymmetricKey(base64EncodedString: stored) {
            return key
        }
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
    case missingApplicationSupportDirectory
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
