import SwiftUI

// MARK: - FormTextField

/// The data necessary for displaying a `FormTextFieldView`.
///
struct FormTextField<State>: Equatable, Identifiable {
    // MARK: Types

    /// An enum describing the behavior for when the input should be automatically capitalized.
    ///
    enum Autocapitalization {
        /// Input is never capitalized.
        case never

        /// The first letter of a sentence should be capitalized.
        case sentences

        /// The first letter of every word should be capitalized.
        case words

        /// Returns the `TextInputAutocapitalization` behavior.
        var textInputAutocapitalization: TextInputAutocapitalization {
            switch self {
            case .never:
                return .never
            case .sentences:
                return .sentences
            case .words:
                return .words
            }
        }
    }

    // MARK: Properties

    /// The behavior for when the input should be automatically capitalized.
    let autocapitalization: Autocapitalization

    /// Whether autocorrect is disabled in the text field.
    let isAutocorrectDisabled: Bool

    /// Whether a password displayed in the text field is visible.
    let isPasswordVisible: Bool?

    /// A key path for updating whether a password displayed in the text field is visible.
    let isPasswordVisibleKeyPath: WritableKeyPath<State, Bool>?

    /// The type of keyboard to display.
    let keyboardType: UIKeyboardType

    /// A key path for updating the backing value for the text field.
    let keyPath: WritableKeyPath<State, String>

    /// The expected type of content input in the text field.
    let textContentType: UITextContentType?

    /// The title of the field.
    let title: String

    /// The current text value.
    let value: String

    // MARK: Identifiable

    var id: String {
        "FormTextField-\(title)"
    }

    // MARK: Initialization

    /// Initialize a `FormTextField`.
    ///
    /// - Parameters:
    ///   - autocapitalization: The behavior for when the input should be automatically capitalized.
    ///     Defaults to `.sentences`.
    ///   - isAutocorrectDisabled: Whether autocorrect is disabled in the text field. Defaults to
    ///     `false`.
    ///   - isPasswordVisible: Whether a password displayed in the text field is visible
    ///   - isPasswordVisibleKeyPath: A key path for updating whether a password displayed in the
    ///     text field is visible.
    ///   - keyboardType: The type of keyboard to display.
    ///   - keyPath: A key path for updating the backing value for the text field.
    ///   - textContentType: The expected type of content input in the text field. Defaults to `nil`.
    ///   - title: The title of the field.
    ///   - value: The current text value.
    init(
        autocapitalization: Autocapitalization = .sentences,
        isAutocorrectDisabled: Bool = false,
        isPasswordVisible: Bool? = nil,
        isPasswordVisibleKeyPath: WritableKeyPath<State, Bool>? = nil,
        keyboardType: UIKeyboardType = .default,
        keyPath: WritableKeyPath<State, String>,
        textContentType: UITextContentType? = nil,
        title: String,
        value: String
    ) {
        self.autocapitalization = autocapitalization
        self.isAutocorrectDisabled = isAutocorrectDisabled
        self.isPasswordVisible = isPasswordVisible
        self.isPasswordVisibleKeyPath = isPasswordVisibleKeyPath
        self.keyboardType = keyboardType
        self.keyPath = keyPath
        self.textContentType = textContentType
        self.title = title
        self.value = value
    }
}

// MARK: - FormTextFieldView

/// A view that displays a text field for display in a form.
///
struct FormTextFieldView<State>: View {
    // MARK: Properties

    /// A closure containing the action to take when the text is changed.
    let action: (String) -> Void

    /// The data for displaying the field.
    let field: FormTextField<State>

    /// A closure containing the action to take when the value for whether a password is displayed
    /// in the text field is changed.
    let isPasswordVisibleChangedAction: ((Bool) -> Void)?

    var body: some View {
        BitwardenTextField(
            title: field.title,
            text: Binding(get: { field.value }, set: action),
            isPasswordVisible: field.isPasswordVisible.map { isPasswordVisible in
                Binding(get: { isPasswordVisible }, set: isPasswordVisibleChangedAction ?? { _ in })
            }
        )
        .autocorrectionDisabled(field.isAutocorrectDisabled)
        .keyboardType(field.keyboardType)
        .textContentType(field.textContentType)
        .textInputAutocapitalization(field.autocapitalization.textInputAutocapitalization)
    }

    // MARK: Initialization

    /// Initialize a `FormTextFieldView`.
    ///
    /// - Parameters:
    ///   - field:  The data for displaying the field.
    ///   - action: A closure containing the action to take when the text is changed.
    ///   - isPasswordVisibleChangedAction: A closure containing the action to take when the value
    ///     for whether a password is displayed in the text field is changed.
    ///
    init(
        field: FormTextField<State>,
        action: @escaping (String) -> Void,
        isPasswordVisibleChangedAction: ((Bool) -> Void)? = nil
    ) {
        self.action = action
        self.field = field
        self.isPasswordVisibleChangedAction = isPasswordVisibleChangedAction
    }
}
