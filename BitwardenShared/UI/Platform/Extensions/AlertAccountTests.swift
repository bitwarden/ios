import XCTest

@testable import BitwardenShared

class AlertAccountTests: BitwardenTestCase {
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
