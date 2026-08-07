import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - DefaultFido2CredentialStoreTests

/// Tests for `DefaultFido2CredentialStore`.
///
class DefaultFido2CredentialStoreTests: BitwardenTestCase {
    // MARK: Properties

    var cipherStorageService: MockCipherStorageService!
    var subject: DefaultFido2CredentialStore!
    var vaultClientService: MockVaultClientService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        cipherStorageService = MockCipherStorageService()
        cipherStorageService.loadCiphersReturnValue = []
        vaultClientService = MockVaultClientService()
        subject = DefaultFido2CredentialStore(
            cipherStorageService: cipherStorageService,
            vaultClientService: vaultClientService,
        )
    }

    override func tearDown() {
        super.tearDown()
        cipherStorageService = nil
        subject = nil
        vaultClientService = nil
    }

    // MARK: Tests

    /// `allCredentials()` returns an empty list when nothing has been saved.
    func test_allCredentials_empty() async throws {
        let result = try await subject.allCredentials()
        XCTAssertTrue(result.isEmpty)
    }

    /// `deleteCredential(cipherId:)` removes the matching cipher and persists the updated list via
    /// the injected `CipherStorageService`.
    func test_deleteCredential_removesMatchingCipher() async throws {
        let first = Cipher(cipherView: .fixture(id: "cipher-1", name: "First"))
        let second = Cipher(cipherView: .fixture(id: "cipher-2", name: "Second"))
        try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: first))
        try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: second))

        await subject.deleteCredential(cipherId: "cipher-1")

        let result = try await subject.allCredentials()
        XCTAssertEqual(result.map(\.name), ["Second"])
        XCTAssertEqual(cipherStorageService.saveReceivedCiphers, [second])
    }

    /// `deleteCredential(cipherId:)` leaves the list unchanged when no cipher matches the given
    /// ID.
    func test_deleteCredential_noMatch_leavesListUnchanged() async throws {
        let cipher = Cipher(cipherView: .fixture(id: "cipher-1", name: "Only"))
        try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: cipher))

        await subject.deleteCredential(cipherId: "nonexistent")

        let result = try await subject.allCredentials()
        XCTAssertEqual(result.map(\.name), ["Only"])
    }

    /// `findCredentials(ids:ripId:userHandle:)` excludes ciphers whose Fido2 credentials don't
    /// match the requested relying party.
    func test_findCredentials_noMatch_returnsEmpty() async throws {
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "Other"))),
        )
        vaultClientService.clientCiphers.decryptFido2CredentialsClosure = { _ in [.fixture(rpId: "other.com")] }

        let result = try await subject.findCredentials(ids: nil, ripId: "bitwarden.com", userHandle: nil)

        XCTAssertTrue(result.isEmpty)
    }

    /// `findCredentials(ids:ripId:userHandle:)` returns the decrypted cipher for a saved
    /// credential whose Fido2 credential matches the requested relying party.
    func test_findCredentials_match_returnsCipherView() async throws {
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "Match"))),
        )
        vaultClientService.clientCiphers.decryptFido2CredentialsClosure = { _ in [.fixture(rpId: "bitwarden.com")] }

        let result = try await subject.findCredentials(ids: nil, ripId: "bitwarden.com", userHandle: nil)

        XCTAssertEqual(result.map(\.name), ["Match"])
    }

    /// `findCredentials(ids:ripId:userHandle:)` only returns the credential matching a
    /// previously `select`ed credential ID, ignoring other credentials registered for the same
    /// relying party.
    func test_findCredentials_afterSelect_onlyReturnsSelectedCredential() async throws {
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "First"))),
        )
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "Second"))),
        )
        vaultClientService.clientCiphers.decryptFido2CredentialsClosure = { cipherView in
            let credentialId = cipherView.name == "First"
                ? "83ddd815-fe03-4e60-6159-c2998f597af1"
                : "f597ad6f-622b-e924-16c5-f78354d49651"
            return [.fixture(credentialId: credentialId, rpId: "bitwarden.com")]
        }

        let secondCredentialId = Data([
            0xF5, 0x97, 0xAD, 0x6F, 0x62, 0x2B, 0xE9, 0x24, 0x16, 0xC5, 0xF7, 0x83, 0x54, 0xD4, 0x96, 0x51,
        ])
        await subject.select(credentialId: secondCredentialId)
        let result = try await subject.findCredentials(ids: nil, ripId: "bitwarden.com", userHandle: nil)

        XCTAssertEqual(result.map(\.name), ["Second"])
    }

    /// `saveCredential(cred:)` makes the credential visible to a subsequent `allCredentials()`
    /// call.
    func test_saveCredential_thenAllCredentials_returnsIt() async throws {
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "Saved"))),
        )

        let result = try await subject.allCredentials()

        XCTAssertEqual(result.map(\.name), ["Saved"])
    }

    /// `saveCredential(cred:)` persists the full, updated list of ciphers via the injected
    /// `CipherStorageService`.
    func test_saveCredential_persistsFullList() async throws {
        let cipher = Cipher(cipherView: .fixture(name: "Saved"))

        try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: cipher))

        XCTAssertEqual(cipherStorageService.saveReceivedCiphers, [cipher])
    }

    /// Ciphers persisted from a previous session are loaded and visible on initialization.
    func test_init_loadsPersistedCiphers() async throws {
        let cipher = Cipher(cipherView: .fixture(name: "Persisted"))
        cipherStorageService.loadCiphersReturnValue = [cipher]

        subject = DefaultFido2CredentialStore(
            cipherStorageService: cipherStorageService,
            vaultClientService: vaultClientService,
        )
        let result = try await subject.allCredentials()

        XCTAssertEqual(result.map(\.name), ["Persisted"])
    }
}
