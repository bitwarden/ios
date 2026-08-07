import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - SDKPasskeyServiceTests

/// Tests for `DefaultSDKPasskeyService`. These exercise the real, local-only `BitwardenSdk`
/// client rather than a mock, since the whole point of this service is driving the actual SDK
/// Fido2 authenticator.
///
class SDKPasskeyServiceTests: BitwardenTestCase {
    // MARK: Properties

    var cipherStorageService: DefaultSDKCipherStorageService!
    var keychainServiceFacade: MockKeychainServiceFacade!
    var subject: DefaultSDKPasskeyService!
    var userDefaults: UserDefaults!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "SDKPasskeyServiceTests")
        userDefaults.removePersistentDomain(forName: "SDKPasskeyServiceTests")
        cipherStorageService = DefaultSDKCipherStorageService(userDefaults: userDefaults)
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
        userDefaults.removePersistentDomain(forName: "SDKPasskeyServiceTests")
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

    // MARK: Private

    /// Builds a new `DefaultSDKPasskeyService` sharing this test's persisted identity and cipher
    /// storage, to simulate a fresh instance picking up state from a previous app launch.
    private func makeSubject() -> DefaultSDKPasskeyService {
        DefaultSDKPasskeyService(
            cipherStorageService: cipherStorageService,
            keychainServiceFacade: keychainServiceFacade,
        )
    }
}
