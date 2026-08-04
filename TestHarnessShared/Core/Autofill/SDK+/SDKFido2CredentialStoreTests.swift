import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - SDKFido2CredentialStoreTests

/// Tests for `SDKFido2CredentialStore`.
///
class SDKFido2CredentialStoreTests: BitwardenTestCase {
    // MARK: Properties

    var subject: SDKFido2CredentialStore!
    var vaultClientService: MockVaultClientService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        vaultClientService = MockVaultClientService()
        subject = SDKFido2CredentialStore(vaultClientService: vaultClientService)
    }

    override func tearDown() {
        super.tearDown()
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

    /// `saveCredential(cred:)` makes the credential visible to a subsequent `allCredentials()`
    /// call.
    func test_saveCredential_thenAllCredentials_returnsIt() async throws {
        try await subject.saveCredential(
            cred: EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: .fixture(name: "Saved"))),
        )

        let result = try await subject.allCredentials()

        XCTAssertEqual(result.map(\.name), ["Saved"])
    }
}
