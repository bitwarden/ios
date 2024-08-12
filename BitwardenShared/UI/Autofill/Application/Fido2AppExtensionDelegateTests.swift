import AuthenticationServices
import XCTest

@testable import BitwardenShared

@available(iOS 17.0, *)
class Fido2AppExtensionDelegateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: MockFido2AppExtensionDelegate!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = MockFido2AppExtensionDelegate()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `getter:autofillListMode`  returns the proper autofill list mode
    func test_autofillListMode() async throws {
        subject.extensionMode = .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters())
        XCTAssertEqual(subject.autofillListMode, .combinedMultipleSections)

        subject.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        XCTAssertEqual(subject.autofillListMode, .combinedSingleSection)

        subject.extensionMode = .autofillVaultList([])
        XCTAssertEqual(subject.autofillListMode, .passwords)
    }

    /// `getter:isCreatingFido2Credential`  returns `true`
    /// when there is a request for creation
    func test_isCreatingFido2Credential_true() async throws {
        subject.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        XCTAssertTrue(subject.isCreatingFido2Credential)
    }

    /// `getter:isCreatingFido2Credential`  returns `false`
    /// when there is no request for creation
    func test_isCreatingFido2Credential_false() async throws {
        XCTAssertFalse(subject.isCreatingFido2Credential)
    }

    /// `getter:rpID`  returns the proper rpID
    func test_rpID() async throws {
        let expectedRpID = "myApp.com"
        subject.extensionMode = .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters(
            relyingPartyIdentifier: expectedRpID
        ))
        XCTAssertEqual(subject.rpID, expectedRpID)

        subject.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture(
            credentialIdentity: .fixture(relyingPartyIdentifier: expectedRpID))
        )
        XCTAssertEqual(subject.rpID, expectedRpID)

        subject.extensionMode = .autofillVaultList([])
        XCTAssertNil(subject.rpID)
    }
}
