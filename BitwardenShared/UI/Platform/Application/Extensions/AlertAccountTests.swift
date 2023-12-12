import XCTest

@testable import BitwardenShared

class AlertAccountTests: BitwardenTestCase {
    /// `logoutOnTimeoutAlert(action:)` constructs an `Alert` with the title, message, and Yes and Cancel buttons.
    func test_logoutOnTimeoutAlert() {
        let subject = Alert.logoutOnTimeoutAlert {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.warning)
        XCTAssertEqual(subject.message, Localizations.vaultTimeoutLogOutConfirmation)
    }
}
