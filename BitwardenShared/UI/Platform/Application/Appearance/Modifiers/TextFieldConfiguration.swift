import SwiftUI

// MARK: - TextFieldConfiguration

/// A struct containing several `TextField` configuration properties that are commonly set on text
/// fields in the app.
///
struct TextFieldConfiguration {
    // MARK: Properties

    /// Whether autocorrect is disabled in the text field.
    let isAutocorrectionDisabled: Bool

    /// The type of keyboard to display.
    let keyboardType: UIKeyboardType?

    /// The expected type of content input in the text field.
    let textContentType: UITextContentType?

    /// The behavior for when the input should be automatically capitalized.
    let textInputAutocapitalization: TextInputAutocapitalization?
}

extension TextFieldConfiguration {
    /// A `TextFieldConfiguration` for applying common properties to email text fields.
    static let email = TextFieldConfiguration(
        isAutocorrectionDisabled: true,
        keyboardType: .emailAddress,
        textContentType: .emailAddress,
        textInputAutocapitalization: .never
    )

    /// A `TextFieldConfiguration` for applying common properties to password text fields.
    static let password = TextFieldConfiguration(
        isAutocorrectionDisabled: true,
        keyboardType: .default,
        textContentType: .password,
        textInputAutocapitalization: .never
    )

    /// A `TextFieldConfiguration` for applying common properties to URL text fields.
    static let url = TextFieldConfiguration(
        isAutocorrectionDisabled: true,
        keyboardType: .URL,
        textContentType: .URL,
        textInputAutocapitalization: .never
    )

    /// A `TextFieldConfiguration` for applying common properties to username text fields.
    static let username = TextFieldConfiguration(
        isAutocorrectionDisabled: true,
        keyboardType: .default,
        textContentType: .username,
        textInputAutocapitalization: .never
    )
}

// MARK: - View

extension View {
    /// A view extension that applies common text field properties based on a configuration.
    ///
    /// - Parameter configuration: The configuration used to set common text field properties.
    /// - Returns: The wrapped view modified with the common text field modifiers applied.
    ///
    func textFieldConfiguration(_ configuration: TextFieldConfiguration) -> some View {
        autocorrectionDisabled(configuration.isAutocorrectionDisabled)
            .keyboardType(configuration.keyboardType ?? .default)
            .textContentType(configuration.textContentType)
            .textInputAutocapitalization(configuration.textInputAutocapitalization)
    }
}
