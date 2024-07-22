import UIKit

@testable import BitwardenShared

enum AlertError: LocalizedError {
    case alertActionNotFound(title: String)
    case alertTextFieldNotFound(id: String)

    var errorDescription: String? {
        switch self {
        case let .alertActionNotFound(title):
            "Unable to locate an alert action for the title: \(title)"
        case let .alertTextFieldNotFound(id):
            "Unable to locate a TextField with id: \(id)"
        }
    }
}

extension Alert {
    /// Simulates a user interaction with the alert action that matches the provided title.
    ///
    /// - Parameters:
    ///   - title: The title of the alert action to trigger.
    ///   - alertTextFields: `AlertTextField` list to execute the action.
    /// - Throws: Throws an `AlertError` if the alert action cannot be found.
    func tapAction(
        title: String,
        alertTextFields: [AlertTextField]? = nil
    ) async throws {
        guard let alertAction = alertActions.first(where: { $0.title == title }) else {
            throw AlertError.alertActionNotFound(title: title)
        }
        await alertAction.handler?(alertAction, alertTextFields ?? self.alertTextFields)
    }

    /// Sets the text for the alert text field with the specified identifier.
    ///
    /// - Parameters:
    ///   - text: The text to set in the alert text field.
    ///   - id: The identifier of the alert text field to set the text for.
    /// - Throws: Throws an `AlertError` if the alert text field cannot be found.
    func setText(
        _ text: String,
        forTextFieldWithId id: String
    ) throws {
        guard let textField = alertTextFields.first(where: { $0.id == id }) else {
            throw AlertError.alertTextFieldNotFound(id: id)
        }

        let simulatedTextField = UITextField()
        simulatedTextField.text = "1234"
        textField.textChanged(in: simulatedTextField)
    }
}
