import BitwardenSdk
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - DefaultFido2UserInterfaceTests

/// Tests for `DefaultFido2UserInterface`.
///
class DefaultFido2UserInterfaceTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultFido2UserInterface!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = DefaultFido2UserInterface()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `checkUser(options:hint:)` always approves presence and verification.
    func test_checkUser_approves() async throws {
        let result = try await subject.checkUser(
            options: CheckUserOptions(requirePresence: true, requireVerification: .required),
            hint: .informNoCredentialsFound,
        )
        XCTAssertTrue(result.userPresent)
        XCTAssertTrue(result.userVerified)
    }

    /// `checkUserAndPickCredentialForCreation(options:newCredential:)` synthesizes a new login
    /// item using the new credential's relying party and username.
    func test_checkUserAndPickCredentialForCreation() async throws {
        let newCredential = Fido2CredentialNewView(
            credentialId: "credential-id",
            keyType: "public-key",
            keyAlgorithm: "ECDSA",
            keyCurve: "P-256",
            rpId: "bitwarden.com",
            userHandle: nil,
            userName: "user@example.com",
            counter: "0",
            rpName: "Bitwarden",
            userDisplayName: "User",
            creationDate: Date(timeIntervalSince1970: 0),
        )
        let result = try await subject.checkUserAndPickCredentialForCreation(
            options: CheckUserOptions(requirePresence: true, requireVerification: .preferred),
            newCredential: newCredential,
        )
        XCTAssertEqual(result.cipher.cipher.name, "Bitwarden")
        XCTAssertEqual(result.cipher.cipher.login?.username, "user@example.com")
        XCTAssertTrue(result.checkUserResult.userPresent)
        XCTAssertTrue(result.checkUserResult.userVerified)
    }

    /// `isVerificationEnabled()` returns `false` since there's no biometrics to back it.
    func test_isVerificationEnabled() {
        XCTAssertFalse(subject.isVerificationEnabled())
    }

    /// `pickCredentialForAuthentication(availableCredentials:)` throws when there are no
    /// candidates.
    func test_pickCredentialForAuthentication_empty_throwsNoMatchingCredential() async {
        await assertAsyncThrows(error: PasskeyError.noMatchingCredential) {
            _ = try await subject.pickCredentialForAuthentication(availableCredentials: [])
        }
    }

    /// `pickCredentialForAuthentication(availableCredentials:)` throws when there's more than one
    /// candidate, since picking between them isn't supported yet.
    func test_pickCredentialForAuthentication_multiple_throwsAmbiguousCredential() async {
        await assertAsyncThrows(error: PasskeyError.ambiguousCredential) {
            _ = try await subject.pickCredentialForAuthentication(availableCredentials: [.fixture(), .fixture()])
        }
    }

    /// `pickCredentialForAuthentication(availableCredentials:)` returns the only candidate when
    /// there's exactly one.
    func test_pickCredentialForAuthentication_single_returnsIt() async throws {
        let cipherView = CipherView.fixture(name: "Only")
        let result = try await subject.pickCredentialForAuthentication(availableCredentials: [cipherView])
        XCTAssertEqual(result.cipher, cipherView)
    }
}
