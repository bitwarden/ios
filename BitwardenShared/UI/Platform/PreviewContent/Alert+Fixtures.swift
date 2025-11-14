import BitwardenKit
import UIKit

#if DEBUG
extension Alert {
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

extension AlertAction {
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

extension AlertTextField {
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
