import XCTest

@testable import BitwardenShared

class AlertAuthTests: BitwardenTestCase {
    /// `breachesAlert(action:)` constructs an `Alert` with the title, message, and Yes and No buttons.
    func test_breachesAlert() {
        let subject = Alert.breachesAlert {}

        XCTAssertEqual(subject.title, Localizations.weakAndExposedMasterPassword)
        XCTAssertEqual(subject.message, Localizations.weakPasswordIdentifiedAndFoundInADataBreachAlertDescription)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.no)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.yes)
    }

    /// `logoutConfirmation(action:)` constructs an `Alert` used to confirm that the user wants to
    /// logout of the account.
    func test_logoutConfirmation() {
        let subject = Alert.logoutConfirmation {}

        XCTAssertEqual(subject.title, Localizations.logOut)
        XCTAssertEqual(subject.message, Localizations.logoutConfirmation)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.cancel)
    }

    /// `passwordExposedAlert()` constructs an alert with the correct title and alert actions.
    func test_passwordExposedAlert() {
        let subject = Alert.passwordExposedAlert(count: 1)

        XCTAssertEqual(subject.title, Localizations.passwordExposed(1))
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.ok)
    }

    /// `passwordSafeAlert()` constructs an alert with the correct title and alert actions.
    func test_passwordSafeAlert() {
        let subject = Alert.passwordSafeAlert()

        XCTAssertEqual(subject.title, Localizations.passwordSafe)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.ok)
    }
}
