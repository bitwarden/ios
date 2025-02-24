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

    /// A `TextFieldConfiguration` for applying common properties to numeric text fields.
    static func numeric(_ textContentType: UITextContentType) -> TextFieldConfiguration {
        TextFieldConfiguration(
            isAutocorrectionDisabled: true,
            keyboardType: .numberPad,
            textContentType: textContentType,
            textInputAutocapitalization: .never
        )
    }

    /// A `TextFieldConfiguration` for applying common properties to one-time code text fields.
    static func oneTimeCode(keyboardType: UIKeyboardType = .numberPad) -> TextFieldConfiguration {
        TextFieldConfiguration(
            isAutocorrectionDisabled: true,
            keyboardType: keyboardType,
            textContentType: .oneTimeCode,
            textInputAutocapitalization: .never
        )
    }
}

extension UITextContentType {
    /// A `.creditCardExpirationYear` value that falls back to `.dateTime`.
    static var creditCardExpirationYearOrDateTime: UITextContentType {
        if #available(iOSApplicationExtension 17.0, *) {
            .creditCardExpirationYear
        } else {
            .dateTime
        }
    }

    /// A `.creditCardName` value that falls back to `.name`.
    static var creditCardNameOrName: UITextContentType {
        if #available(iOSApplicationExtension 17.0, *) {
            .creditCardName
        } else {
            .name
        }
    }

    /// A `.creditCardSecurityCode` value that falls back to `.password`.
    static var creditCardSecurityCodeOrPassword: UITextContentType {
        if #available(iOSApplicationExtension 17.0, *) {
            .creditCardSecurityCode
        } else {
            .password
        }
    }
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
