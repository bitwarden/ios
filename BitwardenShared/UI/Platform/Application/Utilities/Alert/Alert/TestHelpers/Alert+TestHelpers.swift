import BitwardenResources
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
    /// Simulates tapping the cancel button of the alert.
    func tapCancel() async throws {
        try await tapAction(title: Localizations.cancel)
    }

    /// Simulates a user interaction with the alert action that is in the specified index and matches the title.
    /// - Parameters:
    ///   - byIndex: The index to get the alert action.
    ///   - withTitle: The title of the alert action to trigger.
    ///   - alertTextFields: `AlertTextField` list to execute the action
    /// - Throws: Throws an `AlertError` if the alert action cannot be found.
    func tapAction(
        byIndex: Int,
        withTitle: String,
        _ alertTextFields: [AlertTextField]? = nil
    ) async throws {
        let alertAction = alertActions[byIndex]
        guard alertAction.title == withTitle else {
            throw AlertError.alertActionNotFound(title: withTitle)
        }
        await alertAction.handler?(alertAction, alertTextFields ?? self.alertTextFields)
    }

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
        simulatedTextField.text = text
        textField.textChanged(in: simulatedTextField)
    }

    /// Fills the "password" TextField with the `with` parameter and simulatess tapping the "Submit" button.
    /// - Parameter with: Value to enter into the TextField.
    func submitMasterPasswordReprompt(with password: String) async throws {
        try await tapAction(
            title: Localizations.submit,
            alertTextFields: [
                AlertTextField(
                    id: "password",
                    text: password
                ),
            ]
        )
    }
}
