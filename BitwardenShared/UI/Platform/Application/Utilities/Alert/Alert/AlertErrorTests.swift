import BitwardenResources
import XCTest

@testable import BitwardenShared

class AlertErrorTests: BitwardenTestCase {
    /// `defaultAlert(title:message:)` constructs an `Alert` with the title, message, and an OK button.
    func test_defaultAlert() {
        let subject = Alert.defaultAlert(title: "title", message: "message")

        XCTAssertEqual(subject.title, "title")
        XCTAssertEqual(subject.message, "message")
        XCTAssertEqual(subject.alertActions, [AlertAction(title: "Ok", style: .cancel)])
    }

    /// `defaultAlert(error:)` constructs an `Alert` with the title and message based on the error,
    /// and an OK button.
    func test_defaultAlertError() {
        let subject = Alert.defaultAlert(error: StateServiceError.noActiveAccount)

        XCTAssertEqual(subject.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(subject.message, StateServiceError.noActiveAccount.errorDescription)
        XCTAssertEqual(subject.alertActions, [AlertAction(title: "Ok", style: .cancel)])
    }

    /// `inputValidationAlert(error:)` creates an `Alert` for an input validation error.
    func test_inputValidationAlert() {
        let subject = Alert.inputValidationAlert(
            error: InputValidationError(
                message: Localizations.validationFieldRequired(Localizations.masterPassword)
            )
        )

        XCTAssertEqual(subject.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(subject.message, Localizations.validationFieldRequired(Localizations.masterPassword))
        XCTAssertEqual(subject.alertActions, [AlertAction(title: Localizations.ok, style: .default)])
    }
}
