import UIKit

// MARK: - AlertTextField

/// A text field that can be added to an `Alert`. This class allows an `AlertAction` to retrieve a
/// value entered by the user when executing its handler.
///
public class AlertTextField {
    /// The identifier for this text field.
    public var id: String

    /// The placeholder for this text field.
    public var placeholder: String?

    /// The text value entered by the user.
    public private(set) var text: String

    /// How the text should be autocapitalized in this field.
    public let autocapitalizationType: UITextAutocapitalizationType

    /// How the text should be autocorrected in this field.
    public let autocorrectionType: UITextAutocorrectionType

    /// A flag indicating if this text field's contents should be masked.
    public let isSecureTextEntry: Bool

    /// The keyboard type for this text field.
    public let keyboardType: UIKeyboardType

    /// Creates a new `AlertTextField`.
    ///
    /// - Parameters:
    ///   - id: The identifier for this text field. Defaults to a new UUID.
    ///   - autocapitalizationType: How the text should be autocapitalized in this field. Defaults to `.sentences`.
    ///   - autocorrectionType: How the text should be autocorrected in this field. Defaults to `.default`.
    ///   - isSecureTextEntry: A flag indicating if this text field's content should be masked.
    ///   - keyboardType: The keyboard type for this text field. Defaults to `.default`.
    ///   - placeholder: The optional placeholder for this text field. Defaults to `nil`.
    ///   - text: An optional initial value to pre-fill the text field with.
    ///
    public init(
        id: String = UUID().uuidString,
        autocapitalizationType: UITextAutocapitalizationType = .sentences,
        autocorrectionType: UITextAutocorrectionType = .default,
        isSecureTextEntry: Bool = false,
        keyboardType: UIKeyboardType = .default,
        placeholder: String? = nil,
        text: String? = nil
    ) {
        self.id = id
        self.autocapitalizationType = autocapitalizationType
        self.autocorrectionType = autocorrectionType
        self.isSecureTextEntry = isSecureTextEntry
        self.keyboardType = keyboardType
        self.placeholder = placeholder
        self.text = text ?? ""
    }

    @objc
    func textChanged(in textField: UITextField) {
        text = textField.text ?? ""
    }
}

extension AlertTextField: Equatable {
    public static func == (lhs: AlertTextField, rhs: AlertTextField) -> Bool {
        lhs.autocapitalizationType == rhs.autocapitalizationType
            && lhs.autocorrectionType == rhs.autocorrectionType
            && lhs.id == rhs.id
            && lhs.isSecureTextEntry == rhs.isSecureTextEntry
            && lhs.keyboardType == rhs.keyboardType
            && lhs.placeholder == rhs.placeholder
            && lhs.text == rhs.text
    }
}

extension AlertTextField: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(autocapitalizationType)
        hasher.combine(autocorrectionType)
        hasher.combine(id)
        hasher.combine(isSecureTextEntry)
        hasher.combine(keyboardType)
        hasher.combine(placeholder)
        hasher.combine(text)
    }
}
