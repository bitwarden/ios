import BitwardenSdk
import XCTest

@testable import BitwardenShared

class Fido2CredentialAutofillViewExtensionsTests: BitwardenTestCase { // swiftlint:disable:this type_name
    // MARK: Tests

    /// `toFido2CredentialIdentity()` returns the converted `ASPasskeyCredentialIdentity`.
    func test_toFido2CredentialIdentity() throws {
        let subject = Fido2CredentialAutofillView(
            credentialId: Data((0 ..< 16).map { _ in 1 }),
            cipherId: "1",
            rpId: "myApp.com",
            userNameForUi: "username",
            userHandle: Data((0 ..< 16).map { _ in 1 })
        )
        let identity = subject.toFido2CredentialIdentity()
        XCTAssertTrue(
            identity.relyingPartyIdentifier == subject.rpId
                && identity.userName == subject.userNameForUi
                && identity.credentialID == subject.credentialId
                && identity.userHandle == subject.userHandle
                && identity.recordIdentifier == subject.cipherId
        )
    }

    /// `toFido2CredentialIdentity()` returns the converted `ASPasskeyCredentialIdentity`
    /// when `userNameForUI` is `nil`.
    func test_toFido2CredentialIdentity_userNameForUINil() throws {
        let subject = Fido2CredentialAutofillView(
            credentialId: Data((0 ..< 16).map { _ in 1 }),
            cipherId: "1",
            rpId: "myApp.com",
            userNameForUi: nil,
            userHandle: Data((0 ..< 16).map { _ in 1 })
        )
        let identity = subject.toFido2CredentialIdentity()
        XCTAssertTrue(
            identity.relyingPartyIdentifier == subject.rpId
                && identity.userName == Localizations.unknownAccount
                && identity.credentialID == subject.credentialId
                && identity.userHandle == subject.userHandle
                && identity.recordIdentifier == subject.cipherId
        )
    }
}
