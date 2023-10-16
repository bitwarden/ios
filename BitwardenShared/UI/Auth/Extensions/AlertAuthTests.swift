import XCTest

@testable import BitwardenShared

class AlertAuthTests: BitwardenTestCase {
    /// `breachesAlert(action:)` constructs an `Alert` with the title, message, and Yes and No buttons.
    func test_breachesAlert() {
        let subject = Alert.breachesAlert {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.title, Localizations.weakAndExposedMasterPassword)
        XCTAssertEqual(subject.message, Localizations.weakPasswordIdentifiedAndFoundInADataBreachAlertDescription)
    }
}
