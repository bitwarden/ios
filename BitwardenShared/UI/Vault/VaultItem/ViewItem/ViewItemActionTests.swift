import BitwardenResources
import XCTest

@testable import BitwardenShared

class ViewItemActionTests: BitwardenTestCase {
    // MARK: Tests

    /// `eventOnCopy` returns the event to collect for the field.
    func test_eventOnCopy() {
        XCTAssertNil(CopyableField.cardNumber.eventOnCopy)
        XCTAssertEqual(CopyableField.customHiddenField.eventOnCopy, .cipherClientCopiedHiddenField)
        XCTAssertNil(CopyableField.customTextField.eventOnCopy)
        XCTAssertEqual(CopyableField.password.eventOnCopy, .cipherClientCopiedPassword)
        XCTAssertEqual(CopyableField.securityCode.eventOnCopy, .cipherClientCopiedCardCode)
        XCTAssertNil(CopyableField.totp.eventOnCopy)
        XCTAssertNil(CopyableField.uri.eventOnCopy)
        XCTAssertNil(CopyableField.username.eventOnCopy)
        XCTAssertNil(CopyableField.identityName.eventOnCopy)
        XCTAssertNil(CopyableField.company.eventOnCopy)
        XCTAssertNil(CopyableField.socialSecurityNumber.eventOnCopy)
        XCTAssertNil(CopyableField.passportNumber.eventOnCopy)
        XCTAssertNil(CopyableField.licenseNumber.eventOnCopy)
        XCTAssertNil(CopyableField.email.eventOnCopy)
        XCTAssertNil(CopyableField.phone.eventOnCopy)
        XCTAssertNil(CopyableField.fullAddress.eventOnCopy)
        XCTAssertNil(CopyableField.notes.eventOnCopy)
    }

    /// `getter:localizedName` returns the correct localized name for each action.
    func test_localizedName() {
        XCTAssertEqual(CopyableField.cardNumber.localizedName, Localizations.number)
        XCTAssertNil(CopyableField.customHiddenField.localizedName)
        XCTAssertNil(CopyableField.customTextField.localizedName)
        XCTAssertEqual(CopyableField.password.localizedName, Localizations.password)
        XCTAssertEqual(CopyableField.securityCode.localizedName, Localizations.securityCode)
        XCTAssertEqual(CopyableField.sshKeyFingerprint.localizedName, Localizations.fingerprint)
        XCTAssertEqual(CopyableField.sshPrivateKey.localizedName, Localizations.privateKey)
        XCTAssertEqual(CopyableField.sshPublicKey.localizedName, Localizations.publicKey)
        XCTAssertEqual(CopyableField.totp.localizedName, Localizations.totp)
        XCTAssertEqual(CopyableField.uri.localizedName, Localizations.websiteURI)
        XCTAssertEqual(CopyableField.username.localizedName, Localizations.username)
        XCTAssertEqual(CopyableField.identityName.localizedName, Localizations.identityName)
        XCTAssertEqual(CopyableField.company.localizedName, Localizations.company)
        XCTAssertEqual(CopyableField.socialSecurityNumber.localizedName, Localizations.ssn)
        XCTAssertEqual(CopyableField.passportNumber.localizedName, Localizations.passportNumber)
        XCTAssertEqual(CopyableField.licenseNumber.localizedName, Localizations.licenseNumber)
        XCTAssertEqual(CopyableField.email.localizedName, Localizations.email)
        XCTAssertEqual(CopyableField.phone.localizedName, Localizations.phone)
        XCTAssertEqual(CopyableField.fullAddress.localizedName, Localizations.address)
        XCTAssertEqual(CopyableField.notes.localizedName, Localizations.notes)
    }
}
