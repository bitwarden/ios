import SwiftUI
import UIKit

/// A secure text field that exposes `UITextInputPasswordRules` to the OS.
///
/// SwiftUI's `SecureField` does not surface a password-rules modifier, so this
/// `UIViewRepresentable` wraps a `UITextField` with `isSecureTextEntry = true`
/// and applies the supplied `passwordRules` directly. The OS uses these rules to
/// drive the strong-password suggestion UI and to communicate requirements to the
/// active credential provider.
///
struct PasswordRulesSecureField: UIViewRepresentable {
    // MARK: - Coordinator

    /// Bridges UITextField editing events back to the SwiftUI binding.
    ///
    class Coordinator: NSObject, UITextFieldDelegate {
        // MARK: Properties

        @Binding var text: String

        // MARK: Initialization

        init(text: Binding<String>) {
            _text = text
        }

        // MARK: Methods

        @objc
        func textChanged(_ sender: UITextField) {
            text = sender.text ?? ""
        }
    }

    // MARK: Properties

    /// The accessibility identifier applied to the underlying text field.
    let accessibilityIdentifier: String

    /// The placeholder string displayed when the field is empty.
    let placeholder: String

    /// The password rules descriptor forwarded to `UITextInputPasswordRules`.
    let passwordRules: UITextInputPasswordRules

    /// The text content type forwarded to `UITextField.textContentType`.
    let textContentType: UITextContentType

    /// The current field value, bound to the store.
    @Binding var text: String

    // MARK: UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.isSecureTextEntry = true
        field.textContentType = textContentType
        field.passwordRules = passwordRules
        field.placeholder = placeholder
        field.accessibilityIdentifier = accessibilityIdentifier
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.borderStyle = .none
        field.delegate = context.coordinator
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged,
        )
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
}
