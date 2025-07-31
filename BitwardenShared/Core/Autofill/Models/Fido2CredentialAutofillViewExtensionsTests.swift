import BitwardenSdk
import XCTest

import BitwardenResources
@testable import BitwardenShared

class Fido2CredentialAutofillViewExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `toFido2CredentialIdentity()` returns the converted `ASPasskeyCredentialIdentity`.
    func test_toFido2CredentialIdentity() throws {
        let subject = Fido2CredentialAutofillView(
            credentialId: Data(repeating: 1, count: 16),
            cipherId: "1",
            rpId: "myApp.com",
            userNameForUi: "username",
            userHandle: Data(repeating: 1, count: 16)
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
            credentialId: Data(repeating: 1, count: 16),
            cipherId: "1",
            rpId: "myApp.com",
            userNameForUi: nil,
            userHandle: Data(repeating: 1, count: 16)
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
