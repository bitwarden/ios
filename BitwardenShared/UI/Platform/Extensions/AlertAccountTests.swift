import BitwardenResources
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

    /// `requestAnswered()` constructs an `Alert` that notifies the user that a pending login request has been answered.
    func test_requestAnswered() {
        let subject = Alert.requestAnswered {}

        XCTAssertEqual(subject.title, Localizations.thisRequestIsNoLongerValid)
        XCTAssertEqual(subject.message, nil)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.ok)
    }

    /// `requestExpired()` constructs an `Alert` that notifies the user that a pending login request has expired.
    func test_requestExpired() {
        let subject = Alert.requestExpired {}

        XCTAssertEqual(subject.title, Localizations.loginRequestHasAlreadyExpired)
        XCTAssertEqual(subject.message, nil)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.ok)
    }
}
