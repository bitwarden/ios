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
    var clientFido2Service: MockClientFido2Service!
    var platformClientService: MockPlatformClientService!
    var subject: DefaultFido2CredentialStore!
    var vaultClientService: MockVaultClientService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        cipherStorageService = MockCipherStorageService()
        cipherStorageService.loadCiphersReturnValue = []
        clientFido2Service = MockClientFido2Service()
        platformClientService = MockPlatformClientService()
        platformClientService.fido2ReturnValue = clientFido2Service
        vaultClientService = MockVaultClientService()
        subject = DefaultFido2CredentialStore(
            cipherStorageService: cipherStorageService,
            platformClientService: platformClientService,
            vaultClientService: vaultClientService,
        )
    }

    override func tearDown() {
        super.tearDown()
        cipherStorageService = nil
        clientFido2Service = nil
        platformClientService = nil
        subject = nil
        vaultClientService = nil
    }

    // MARK: Tests

    /// `allCredentials()` returns an empty list when nothing has been saved.
    func test_allCredentials_empty() async throws {
        let result = try await subject.allCredentials()
        XCTAssertTrue(result.isEmpty)
    }

    /// `findCredentials(ids:ripId:userHandle:)` excludes ciphers whose Fido2 credentials don't
    /// match the requested relying party.
    func test_findCredentials_noMatch_returnsEmpty() async throws {
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "Other"))),
        )
        clientFido2Service.decryptFido2AutofillCredentialsClosure = { _ in [.fixture(rpId: "other.com")] }

        let result = try await subject.findCredentials(ids: nil, ripId: "bitwarden.com", userHandle: nil)

        XCTAssertTrue(result.isEmpty)
    }

    /// `findCredentials(ids:ripId:userHandle:)` returns the decrypted cipher for a saved
    /// credential whose Fido2 credential matches the requested relying party.
    func test_findCredentials_match_returnsCipherView() async throws {
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "Match"))),
        )
        clientFido2Service.decryptFido2AutofillCredentialsClosure = { _ in [.fixture(rpId: "bitwarden.com")] }

        let result = try await subject.findCredentials(ids: nil, ripId: "bitwarden.com", userHandle: nil)

        XCTAssertEqual(result.map(\.name), ["Match"])
    }

    /// `findCredentials(ids:ripId:userHandle:)` only returns the credential whose ID is in
    /// `ids`, ignoring other credentials registered for the same relying party.
    func test_findCredentials_withIds_onlyReturnsMatchingCredential() async throws {
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "First"))),
        )
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "Second"))),
        )
        let firstCredentialId = Data([0x01])
        let secondCredentialId = Data([0x02])
        clientFido2Service.decryptFido2AutofillCredentialsClosure = { cipherView in
            let credentialId = cipherView.name == "First" ? firstCredentialId : secondCredentialId
            return [.fixture(credentialId: credentialId, rpId: "bitwarden.com")]
        }

        let result = try await subject.findCredentials(
            ids: [secondCredentialId],
            ripId: "bitwarden.com",
            userHandle: nil,
        )

        XCTAssertEqual(result.map(\.name), ["Second"])
    }

    /// `findCredentials(ids:ripId:userHandle:)` only returns the credential matching
    /// `userHandle`, ignoring other credentials registered for the same relying party.
    func test_findCredentials_withUserHandle_onlyReturnsMatchingCredential() async throws {
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "First"))),
        )
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "Second"))),
        )
        let firstUserHandle = Data([0x01])
        let secondUserHandle = Data([0x02])
        clientFido2Service.decryptFido2AutofillCredentialsClosure = { cipherView in
            let userHandle = cipherView.name == "First" ? firstUserHandle : secondUserHandle
            return [.fixture(rpId: "bitwarden.com", userHandle: userHandle)]
        }

        let result = try await subject.findCredentials(
            ids: nil,
            ripId: "bitwarden.com",
            userHandle: secondUserHandle,
        )

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

    /// `saveCredential(cred:)` replaces the existing cipher with the same ID rather than
    /// appending a duplicate, so a re-save (e.g. a signature-counter update) doesn't leave two
    /// entries behind for the same credential.
    func test_saveCredential_existingId_replacesExistingCipher() async throws {
        let original = Cipher(cipherView: .fixture(id: "1", name: "Original"))
        try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: original))

        let updated = Cipher(cipherView: .fixture(id: "1", name: "Updated"))
        try await subject.saveCredential(cred: EncryptionContext(encryptedFor: "1", cipher: updated))

        let result = try await subject.allCredentials()
        XCTAssertEqual(result.map(\.name), ["Updated"])
        XCTAssertEqual(cipherStorageService.saveReceivedCiphers, [updated])
    }

    /// Ciphers persisted from a previous session are loaded and visible on initialization.
    func test_init_loadsPersistedCiphers() async throws {
        let cipher = Cipher(cipherView: .fixture(name: "Persisted"))
        cipherStorageService.loadCiphersReturnValue = [cipher]

        subject = DefaultFido2CredentialStore(
            cipherStorageService: cipherStorageService,
            platformClientService: platformClientService,
            vaultClientService: vaultClientService,
        )
        let result = try await subject.allCredentials()

        XCTAssertEqual(result.map(\.name), ["Persisted"])
    }
}
