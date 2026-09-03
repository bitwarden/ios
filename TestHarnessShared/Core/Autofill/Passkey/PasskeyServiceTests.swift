import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - PasskeyServiceTests

/// Tests for `DefaultPasskeyService`. These exercise the real, local-only `BitwardenSdk`
/// client rather than a mock, since the whole point of this service is driving the actual SDK
/// Fido2 authenticator.
///
class PasskeyServiceTests: BitwardenTestCase {
    // MARK: Properties

    var cipherStorageService: DefaultCipherStorageService!
    var keychainServiceFacade: MockKeychainServiceFacade!
    var subject: DefaultPasskeyService!
    var userDefaults: UserDefaults!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "PasskeyServiceTests")
        userDefaults.removePersistentDomain(forName: "PasskeyServiceTests")
        cipherStorageService = DefaultCipherStorageService(userDefaults: userDefaults)
        keychainServiceFacade = MockKeychainServiceFacade()

        var storedIdentity: String?
        keychainServiceFacade.getValueClosure = { item in
            guard let storedIdentity else { throw KeychainServiceError.keyNotFound(item) }
            return storedIdentity
        }
        keychainServiceFacade.setValueClosure = { value, _ in storedIdentity = value }

        subject = makeSubject()
    }

    override func tearDown() {
        super.tearDown()
        userDefaults.removePersistentDomain(forName: "PasskeyServiceTests")
        cipherStorageService = nil
        keychainServiceFacade = nil
        subject = nil
        userDefaults = nil
    }

    // MARK: Tests

    /// `assertPasskey(credentialId:rpId:)` throws when there's no credential registered for the
    /// relying party.
    func test_assertPasskey_noRegisteredCredential_throws() async {
        await assertAsyncThrows {
            _ = try await subject.assertPasskey(credentialId: nil, rpId: "nobody-registered-here.example.com")
        }
    }

    /// `assertPasskey(credentialId:rpId:)` selects the specific credential passed in, even when
    /// multiple credentials are registered for the same relying party.
    func test_assertPasskey_specificCredentialId_selectsThatCredential() async throws {
        _ = try await subject.registerPasskey(
            rpId: "bitwarden.com",
            userName: "user1@example.com",
            displayName: "User One",
        )
        let second = try await subject.registerPasskey(
            rpId: "bitwarden.com",
            userName: "user2@example.com",
            displayName: "User Two",
        )

        let assertion = try await subject.assertPasskey(credentialId: second.credentialId, rpId: "bitwarden.com")

        XCTAssertEqual(assertion.selectedCredential.credential.userName, "user2@example.com")
    }

    /// `deleteCredential(cipherId:)` removes a registered credential so it's no longer listed.
    func test_deleteCredential_removesRegisteredCredential() async throws {
        _ = try await subject.registerPasskey(
            rpId: "bitwarden.com",
            userName: "user@example.com",
            displayName: "User",
        )
        let registered = try await subject.registeredCredentials()
        let cipherId = try XCTUnwrap(registered.first?.cipherId)

        try await subject.deleteCredential(cipherId: cipherId)

        let credentials = try await subject.registeredCredentials()
        XCTAssertTrue(credentials.isEmpty)
    }

    /// `registerPasskey(rpId:userName:displayName:)` returns a non-empty credential ID and
    /// attestation object.
    func test_registerPasskey_returnsCredential() async throws {
        let result = try await subject.registerPasskey(
            rpId: "bitwarden.com",
            userName: "user@example.com",
            displayName: "User",
        )

        XCTAssertFalse(result.credentialId.isEmpty)
        XCTAssertFalse(result.attestationObject.isEmpty)
    }

    /// A credential registered by one service instance remains registered and assertable by a
    /// fresh instance sharing the same persisted identity and cipher storage — simulating an app
    /// relaunch.
    func test_registerPasskey_persistsAcrossServiceInstances() async throws {
        _ = try await subject.registerPasskey(
            rpId: "bitwarden.com",
            userName: "user@example.com",
            displayName: "User",
        )

        let relaunchedSubject = makeSubject()
        let assertion = try await relaunchedSubject.assertPasskey(credentialId: nil, rpId: "bitwarden.com")

        XCTAssertEqual(assertion.selectedCredential.credential.userName, "user@example.com")
    }

    /// A credential registered via `registerPasskey` can subsequently be asserted via
    /// `assertPasskey`, and the assertion resolves back to the same username.
    func test_registerPasskey_thenAssertPasskey_matchesRegisteredUser() async throws {
        _ = try await subject.registerPasskey(
            rpId: "bitwarden.com",
            userName: "user@example.com",
            displayName: "User",
        )

        let assertion = try await subject.assertPasskey(credentialId: nil, rpId: "bitwarden.com")

        XCTAssertEqual(assertion.selectedCredential.credential.userName, "user@example.com")
    }

    /// `registeredCredentials()` reflects a credential registered via `registerPasskey`.
    func test_registeredCredentials_returnsRegisteredCredential() async throws {
        let registration = try await subject.registerPasskey(
            rpId: "bitwarden.com",
            userName: "user@example.com",
            displayName: "User",
        )

        let credentials = try await subject.registeredCredentials()

        XCTAssertEqual(credentials.map(\.credentialId), [registration.credentialId])
        XCTAssertEqual(credentials.map(\.rpId), ["bitwarden.com"])
    }

    /// When the persisted identity can't be loaded on a later launch — e.g. a backup restored the
    /// `UserDefaults`-backed ciphers to a new device without the `ThisDeviceOnly`-scoped keychain
    /// identity — the newly-minted identity discards those now-undecryptable orphaned ciphers,
    /// rather than leaving the store permanently wedged trying to decrypt them under the wrong key.
    func test_registerPasskey_identityLost_discardsOrphanedCiphers() async throws {
        _ = try await subject.registerPasskey(
            rpId: "bitwarden.com",
            userName: "user@example.com",
            displayName: "User",
        )

        let identityLostKeychainServiceFacade = MockKeychainServiceFacade()
        identityLostKeychainServiceFacade.getValueClosure = { item in throw KeychainServiceError.keyNotFound(item) }
        identityLostKeychainServiceFacade.setValueClosure = { _, _ in }
        let relaunchedSubject = DefaultPasskeyService(
            cipherStorageService: cipherStorageService,
            keychainServiceFacade: identityLostKeychainServiceFacade,
        )

        // Without discarding the orphaned cipher above, this cipher — encrypted under the new
        // identity's key — would sit alongside the undecryptable one, and any read touching the
        // old cipher would throw rather than merely returning an empty list.
        let registration = try await relaunchedSubject.registerPasskey(
            rpId: "bitwarden.com",
            userName: "user2@example.com",
            displayName: "User Two",
        )
        let assertion = try await relaunchedSubject.assertPasskey(credentialId: nil, rpId: "bitwarden.com")

        XCTAssertEqual(assertion.credentialId, registration.credentialId)
    }

    // MARK: Private

    /// Builds a new `DefaultPasskeyService` sharing this test's persisted identity and cipher
    /// storage, to simulate a fresh instance picking up state from a previous app launch.
    private func makeSubject() -> DefaultPasskeyService {
        DefaultPasskeyService(
            cipherStorageService: cipherStorageService,
            keychainServiceFacade: keychainServiceFacade,
        )
    }
}
