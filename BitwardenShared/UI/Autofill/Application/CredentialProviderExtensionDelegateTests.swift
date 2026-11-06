import AuthenticationServices
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@available(iOS 17.0, *)
class CredentialProviderExtensionDelegateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: MockCredentialProviderExtensionDelegate!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = MockCredentialProviderExtensionDelegate()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `getter:autofillListMode`  returns the proper autofill list mode
    @MainActor
    func test_autofillListMode() async throws {
        subject.extensionMode = .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters())
        XCTAssertEqual(subject.autofillListMode, .combinedMultipleSections)

        subject.extensionMode = .autofillOTP([])
        XCTAssertEqual(subject.autofillListMode, .totp)

        subject.extensionMode = .autofillText
        XCTAssertEqual(subject.autofillListMode, .all)

        subject.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        XCTAssertEqual(subject.autofillListMode, .combinedSingleSection)

        subject.extensionMode = .autofillVaultList([])
        XCTAssertEqual(subject.autofillListMode, .passwords)

        subject.extensionMode = .savePasswordCredential(MockSavePasswordRequestProxy(), userInteraction: true)
        XCTAssertEqual(subject.autofillListMode, .passwords)
    }

    /// `getter:isAutofillingFido2CredentialFromList` returns `true` when in `autofillFido2VaultList` mode.
    @MainActor
    func test_isAutofillingFido2CredentialFromList_true() {
        subject.extensionMode = .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters())
        XCTAssertTrue(subject.isAutofillingFido2CredentialFromList)
    }

    /// `getter:isAutofillingFido2CredentialFromList` returns `false` when not in `autofillFido2VaultList` mode.
    @MainActor
    func test_isAutofillingFido2CredentialFromList_false() {
        subject.extensionMode = .autofillVaultList([])
        XCTAssertFalse(subject.isAutofillingFido2CredentialFromList)
    }

    /// `getter:isSavingPasswordCredential` returns `true` when in `savePasswordCredential` mode with user interaction.
    @MainActor
    func test_isSavingPasswordCredential_true() {
        subject.extensionMode = .savePasswordCredential(MockSavePasswordRequestProxy(), userInteraction: true)
        XCTAssertTrue(subject.isSavingPasswordCredential)
    }

    /// `getter:isSavingPasswordCredential` returns `false` when in `savePasswordCredential` mode
    /// without user interaction.
    @MainActor
    func test_isSavingPasswordCredential_falseNoUserInteraction() {
        subject.extensionMode = .savePasswordCredential(MockSavePasswordRequestProxy(), userInteraction: false)
        XCTAssertFalse(subject.isSavingPasswordCredential)
    }

    /// `getter:isSavingPasswordCredential` returns `false` when not in `savePasswordCredential` mode.
    @MainActor
    func test_isSavingPasswordCredential_falseOtherMode() {
        subject.extensionMode = .autofillVaultList([])
        XCTAssertFalse(subject.isSavingPasswordCredential)
    }

    /// `getter:isCreatingFido2Credential`  returns `true`
    /// when there is a request for creation
    @MainActor
    func test_isCreatingFido2Credential_true() async throws {
        subject.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture())
        XCTAssertTrue(subject.isCreatingFido2Credential)
    }

    /// `getter:isCreatingFido2Credential`  returns `false`
    /// when there is no request for creation
    @MainActor
    func test_isCreatingFido2Credential_false() async throws {
        XCTAssertFalse(subject.isCreatingFido2Credential)
    }

    /// `getter:rpID`  returns the proper rpID
    @MainActor
    func test_rpID() async throws {
        let expectedRpID = "myApp.com"
        subject.extensionMode = .autofillFido2VaultList([], MockPasskeyCredentialRequestParameters(
            relyingPartyIdentifier: expectedRpID,
        ))
        XCTAssertEqual(subject.rpID, expectedRpID)

        subject.extensionMode = .registerFido2Credential(ASPasskeyCredentialRequest.fixture(
            credentialIdentity: .fixture(relyingPartyIdentifier: expectedRpID),
        ))
        XCTAssertEqual(subject.rpID, expectedRpID)

        subject.extensionMode = .autofillVaultList([])
        XCTAssertNil(subject.rpID)
    }

    /// `getter:rpID` returns `nil` when in `registerFido2Credential` mode with a proxy that cannot
    /// be cast to `ASPasskeyCredentialRequest`.
    @MainActor
    func test_rpID_registerFido2Credential_proxyNotCastable() {
        subject.extensionMode = .registerFido2Credential(MockPasskeyCredentialRequest())
        XCTAssertNil(subject.rpID)
    }
}

// MARK: - Mocks

private class MockSavePasswordRequestProxy: SavePasswordRequestProxy {}
