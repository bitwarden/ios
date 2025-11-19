import UIKit

#if DEBUG
public extension Alert {
    /// Creates a test fixture for an `Alert` with customizable properties.
    ///
    /// This fixture is intended for use in tests, previews, and debugging scenarios.
    ///
    /// - Parameters:
    ///   - title: The title of the alert. Defaults to "🍎".
    ///   - message: The optional message text displayed in the alert. Defaults to "🥝".
    ///   - preferredStyle: The style of the alert controller. Defaults to `.alert`.
    ///   - alertActions: The actions to display in the alert. Defaults to a single OK action.
    ///   - alertTextFields: The text fields to display in the alert. Defaults to a single fixture text field.
    ///
    /// - Returns: An `Alert` configured with the specified properties.
    ///
    static func fixture(
        title: String = "🍎",
        message: String? = "🥝",
        preferredStyle: UIAlertController.Style = .alert,
        alertActions: [AlertAction] = [.ok()],
        alertTextFields: [AlertTextField] = [.fixture()],
    ) -> Alert {
        Alert(
            title: title,
            message: message,
            preferredStyle: preferredStyle,
            alertActions: alertActions,
            alertTextFields: alertTextFields,
        )
    }
}

public extension AlertAction {
    /// Creates an OK-style alert action.
    ///
    /// This factory method creates an alert action with a default "OK" title and default style,
    /// suitable for positive confirmation actions.
    ///
    /// - Parameters:
    ///   - title: The title of the action. Defaults to "OK".
    ///   - style: The style of the action button. Defaults to `.default`.
    ///   - handler: An optional async closure called when the action is triggered.
    ///     Receives the action and current text fields as parameters.
    ///   - shouldEnableAction: An optional closure that determines whether the action should be enabled
    ///     based on the current state of text fields.
    ///
    /// - Returns: An `AlertAction` configured as an OK action.
    ///
    static func ok(
        title: String = "OK",
        style: UIAlertAction.Style = .default,
        handler: ((AlertAction, [AlertTextField]) async -> Void)? = nil,
        shouldEnableAction: (([AlertTextField]) -> Bool)? = nil,
    ) -> AlertAction {
        AlertAction(
            title: title,
            style: style,
            handler: handler,
            shouldEnableAction: shouldEnableAction,
        )
    }

    /// Creates a Cancel-style alert action.
    ///
    /// This factory method creates an alert action with a default "Cancel" title and cancel style,
    /// suitable for dismissive or cancellation actions.
    ///
    /// - Parameters:
    ///   - title: The title of the action. Defaults to "Cancel".
    ///   - style: The style of the action button. Defaults to `.cancel`.
    ///   - handler: An optional async closure called when the action is triggered.
    ///     Receives the action and current text fields as parameters.
    ///   - shouldEnableAction: An optional closure that determines whether the action should be enabled
    ///     based on the current state of text fields.
    ///
    /// - Returns: An `AlertAction` configured as a Cancel action.
    ///
    static func cancel(
        title: String = "Cancel",
        style: UIAlertAction.Style = .cancel,
        handler: ((AlertAction, [AlertTextField]) async -> Void)? = nil,
        shouldEnableAction: (([AlertTextField]) -> Bool)? = nil,
    ) -> AlertAction {
        AlertAction(
            title: title,
            style: style,
            handler: handler,
            shouldEnableAction: shouldEnableAction,
        )
    }
}

public extension AlertTextField {
    /// Creates a test fixture for an `AlertTextField` with customizable properties.
    ///
    /// This fixture is intended for use in tests, previews, and debugging scenarios.
    /// By default, it creates a secure text field with numeric keyboard input.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the text field. Defaults to "field".
    ///   - autocapitalizationType: The auto-capitalization style for the text field. Defaults to `.allCharacters`.
    ///   - autocorrectionType: The autocorrection behavior for the text field. Defaults to `.yes`.
    ///   - isSecureTextEntry: Whether the text field obscures entered text for password entry. Defaults to `true`.
    ///   - keyboardType: The keyboard type to display. Defaults to `.numberPad`.
    ///   - placeholder: The placeholder text displayed when the field is empty. Defaults to "placeholder".
    ///   - text: The initial text value of the field. Defaults to "value".
    ///
    /// - Returns: An `AlertTextField` configured with the specified properties.
    ///
    static func fixture(
        id: String = "field",
        autocapitalizationType: UITextAutocapitalizationType = .allCharacters,
        autocorrectionType: UITextAutocorrectionType = .yes,
        isSecureTextEntry: Bool = true,
        keyboardType: UIKeyboardType = .numberPad,
        placeholder: String? = "placeholder",
        text: String = "value",
    ) -> AlertTextField {
        AlertTextField(
            id: id,
            autocapitalizationType: autocapitalizationType,
            autocorrectionType: autocorrectionType,
            isSecureTextEntry: isSecureTextEntry,
            keyboardType: keyboardType,
            placeholder: placeholder,
            text: text,
        )
    }
}
#endif
