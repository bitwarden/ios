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

    var subject: DefaultSDKPasskeyService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = DefaultSDKPasskeyService()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `assertPasskey(rpId:)` throws when there's no credential registered for the relying
    /// party.
    func test_assertPasskey_noRegisteredCredential_throws() async {
        await assertAsyncThrows {
            _ = try await subject.assertPasskey(rpId: "nobody-registered-here.example.com")
        }
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

    /// A credential registered via `registerPasskey` can subsequently be asserted via
    /// `assertPasskey`, and the assertion resolves back to the same username.
    func test_registerPasskey_thenAssertPasskey_matchesRegisteredUser() async throws {
        _ = try await subject.registerPasskey(
            rpId: "bitwarden.com",
            userName: "user@example.com",
            displayName: "User",
        )

        let assertion = try await subject.assertPasskey(rpId: "bitwarden.com")

        XCTAssertEqual(assertion.selectedCredential.credential.userName, "user@example.com")
    }
}
