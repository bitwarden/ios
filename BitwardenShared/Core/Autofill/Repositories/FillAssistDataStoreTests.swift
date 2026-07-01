import BitwardenKit
import BitwardenKitMocks
import CryptoKit
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - FillAssistDataStoreTests

@MainActor
struct FillAssistDataStoreTests {
    // MARK: Properties

    let keychainRepository: MockKeychainRepository
    let subject: DefaultFillAssistDataStore
    let tempDirectory: URL

    // MARK: Initialization

    init() throws {
        keychainRepository = MockKeychainRepository()
        // Simulate "key not found" so encryptionKey() generates a fresh key rather than
        // returning nil from the uninitialised String! mock return value.
        keychainRepository.getUserAuthKeyValueThrowableError = KeychainServiceError
            .keyNotFound(BitwardenKeychainItem.fillAssistEncryptionKey(userId: "1"))
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        subject = DefaultFillAssistDataStore(
            keychainRepository: keychainRepository,
            overrideBaseURL: tempDirectory,
        )
    }

    // MARK: Tests - save and load round-trip

    /// `save(_:userId:)` encrypts and writes data; `load(userId:)` decrypts and returns it.
    @Test
    func saveAndLoad_roundTrip() async throws {
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let data = FillAssistCachedData(
            cid: "sha256:abc",
            rules: ["example.com": FillAssistHostRules(fields: [:])],
            sourceUrl: "https://example.com",
        )

        try await subject.save(data, userId: "1")
        // After save, the generated key is in the mock; make subsequent calls return it.
        let storedKey = keychainRepository.setUserAuthKeyReceivedArguments?.value ?? ""
        keychainRepository.getUserAuthKeyValueThrowableError = nil
        keychainRepository.getUserAuthKeyValueReturnValue = storedKey

        let loaded = try await subject.load(userId: "1")

        #expect(loaded == data)
        #expect(keychainRepository.setUserAuthKeyCalled)
    }

    /// `load(userId:)` returns `nil` when no file exists for the user.
    @Test
    func load_noFile_returnsNil() async throws {
        let result = try await subject.load(userId: "nonexistent")
        #expect(result == nil)
    }

    /// `save(_:userId:)` reuses the existing Keychain key on subsequent saves.
    @Test
    func save_reuseExistingKey() async throws {
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let data = FillAssistCachedData(cid: "sha256:abc", rules: [:], sourceUrl: "https://example.com")

        // First save: no key yet → generates and stores one.
        try await subject.save(data, userId: "1")
        let storedKey = keychainRepository.setUserAuthKeyReceivedArguments?.value ?? ""
        // Second save: key exists → getUserAuthKeyValue returns it, no new key generated.
        keychainRepository.getUserAuthKeyValueThrowableError = nil
        keychainRepository.getUserAuthKeyValueReturnValue = storedKey

        try await subject.save(data, userId: "1")

        #expect(keychainRepository.setUserAuthKeyCallsCount == 1, "Key should be generated only once")
    }

    /// `load(userId:)` propagates Keychain errors rather than generating a new key.
    @Test
    func load_keychainError_propagates() async throws {
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let data = FillAssistCachedData(cid: "sha256:abc", rules: [:], sourceUrl: "https://example.com")
        // Save to create the encrypted file.
        try await subject.save(data, userId: "1")
        // Simulate a Keychain error (e.g. locked device) on the subsequent load.
        keychainRepository.getUserAuthKeyValueThrowableError = URLError(.notConnectedToInternet)

        await #expect(throws: URLError.self) {
            _ = try await subject.load(userId: "1")
        }
        #expect(keychainRepository.setUserAuthKeyCallsCount == 1, "Must not generate a new key on Keychain error")
    }

    /// `delete(userId:)` removes the file and deletes the Keychain key.
    @Test
    func delete_removesFileAndKey() async throws {
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let data = FillAssistCachedData(cid: "sha256:abc", rules: [:], sourceUrl: "https://example.com")
        try await subject.save(data, userId: "1")

        try await subject.delete(userId: "1")

        let loaded = try await subject.load(userId: "1")
        #expect(loaded == nil)
        #expect(keychainRepository.deleteUserAuthKeyCalled)
    }

    /// `delete(userId:)` succeeds even if no file exists.
    @Test
    func delete_noFile_succeeds() async throws {
        await #expect(throws: Never.self) {
            try await subject.delete(userId: "nonexistent")
        }
    }
}
