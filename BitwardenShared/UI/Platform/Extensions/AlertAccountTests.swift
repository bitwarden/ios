import XCTest

@testable import BitwardenShared

class AlertAccountTests: BitwardenTestCase {
    /// `deleteAccountAlert(action:)` constructs an `Alert` with the title, message, and Yes and No buttons.
    func test_deleteAccountAlert() {
        let subject = Alert.deleteAccountAlert {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.passwordConfirmation)
        XCTAssertEqual(subject.message, Localizations.passwordConfirmationDesc)
    }

    /// `accountDeletedAlert()` constructs an `Alert` that notifies the user of their account deletion.
    func test_accountDeleted() {
        let subject = Alert.accountDeletedAlert()

        XCTAssertEqual(subject.title, Localizations.yourAccountHasBeenPermanentlyDeleted)
        XCTAssertEqual(subject.message, nil)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.ok)
    }
}
