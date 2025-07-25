import BitwardenResources
import UIKit

extension GeneratorState {
    /// Data model containing the list of fields to display grouped together in a section of a form.
    ///
    struct FormSectionGroup<State>: Equatable, Identifiable {
        // MARK: Properties

        /// The list of fields to display grouped together in the section.
        let fields: [FormField<State>]

        /// The group's unique identifier.
        let id: String

        /// Whether the content in the group should be shown in a content block.
        let showInContentBlock: Bool

        // MARK: Initialization

        /// Initialize a `FormSectionGroup`.
        ///
        /// - Parameters:
        ///   - fields: The list of fields to display grouped together in the section.
        ///   - id: The groups's unique identifier.
        ///   - showInContentBlock: Whether the content in the group should be shown in a content block.
        ///
        init(fields: [FormField<State>], id: String, showInContentBlock: Bool = true) {
            self.fields = fields
            self.id = id
            self.showInContentBlock = showInContentBlock
        }
    }

    /// Data model containing the data to display a section of fields in a form.
    ///
    struct FormSection<State>: Equatable, Identifiable {
        // MARK: Properties

        /// The groups of fields to display in the section.
        let groups: [FormSectionGroup<State>]

        /// The section's unique identifier.
        let id: String

        /// The section's title.
        let title: String?
    }

    /// Data model representing a field to display in a form.
    ///
    struct FormField<State>: Equatable, Identifiable {
        // MARK: Types

        /// The supported types of fields.
        ///
        enum FieldType: Equatable, Identifiable { // swiftlint:disable:this nesting
            /// A static field for displaying the email website.
            case emailWebsite(String)

            /// A generated value field.
            case generatedValue(GeneratedValueField<State>)

            /// A menu field for the email type.
            case menuEmailType(FormMenuField<State, UsernameEmailType>)

            /// A menu field for the user generator type.
            case menuUsernameGeneratorType(FormMenuField<State, UsernameGeneratorType>)

            /// A menu field for username forwarded email service.
            case menuUsernameForwardedEmailService(FormMenuField<State, ForwardedEmailServiceType>)

            /// A slider field.
            case slider(SliderField<State>)

            /// A stepper field.
            case stepper(StepperField<State>)

            /// A text field.
            case text(FormTextField<State>)

            /// A toggle field.
            case toggle(ToggleField<State>)

            // MARK: Identifiable

            var id: String {
                switch self {
                case let .emailWebsite(website):
                    return website
                case let .generatedValue(field):
                    return field.id
                case let .menuEmailType(field):
                    return field.id
                case let .menuUsernameGeneratorType(field):
                    return field.id
                case let .menuUsernameForwardedEmailService(field):
                    return field.id
                case let .slider(field):
                    return field.id
                case let .stepper(field):
                    return field.id
                case let .text(field):
                    return field.id
                case let .toggle(field):
                    return field.id
                }
            }
        }

        // MARK: Properties

        /// The type of field to display.
        let fieldType: FieldType

        // MARK: Identifiable

        var id: String { fieldType.id }
    }

    /// The data necessary for displaying the generated value field. This is used to display the
    /// generated password, username or email.
    ///
    struct GeneratedValueField<State>: Equatable, Identifiable {
        // MARK: Properties

        /// A key path for updating the backing value for the generated value field.
        var keyPath: WritableKeyPath<State, String>

        /// The current generated value.
        var value: String

        // MARK: Identifiable

        var id: String { "GeneratedValue" }
    }
}

extension GeneratorState {
    // MARK: Form Field Helpers

    /// A helper method for creating a menu field for the email type.
    ///
    /// - Parameter keyPath: A key path for getting and setting the backing value for the field.
    /// - Returns: A form field for an email type field.
    ///
    func emailTypeField(keyPath: WritableKeyPath<GeneratorState, UsernameEmailType>) -> FormField<Self> {
        FormField(fieldType: .menuEmailType(
            FormMenuField(
                accessibilityIdentifier: "EmailTypePicker",
                keyPath: keyPath,
                options: UsernameEmailType.allCases,
                selection: self[keyPath: keyPath],
                title: Localizations.emailType
            )
        ))
    }

    /// A helper method for creating a generated value field.
    ///
    /// - Parameter keyPath: A key path for getting and setting the backing value for the field.
    /// - Returns: A form field for a generated value field.
    ///
    func generatedValueField(keyPath: WritableKeyPath<GeneratorState, String>) -> FormField<Self> {
        FormField(fieldType: .generatedValue(
            GeneratedValueField(keyPath: keyPath, value: self[keyPath: keyPath])
        ))
    }

    /// A helper method for creating a slider field.
    ///
    /// - Parameters:
    ///   - keyPath: A key path for getting and setting the backing value for the field.
    ///   - range: The range of allowable values for the slider.
    ///   - sliderAccessibilityId: The accessibility id for the slider.
    ///   - sliderValueAccessibilityId: The accessibility id for the slider value.
    ///   - title: The title of the field.
    ///   - step: The distance between each valid value.
    /// - Returns: A form field for a slider field.
    ///
    func sliderField(
        keyPath: WritableKeyPath<GeneratorState, Double>,
        range: ClosedRange<Double>,
        sliderAccessibilityId: String? = nil,
        sliderValueAccessibilityId: String? = nil,
        title: String,
        step: Double
    ) -> FormField<Self> {
        FormField(fieldType: .slider(
            SliderField(
                keyPath: keyPath,
                range: range,
                sliderAccessibilityId: sliderAccessibilityId,
                sliderValueAccessibilityId: sliderValueAccessibilityId,
                step: step,
                title: title,
                value: self[keyPath: keyPath]
            )
        ))
    }

    /// A helper method for creating a stepper field.
    ///
    /// - Parameters:
    ///   - accessibilityId: The accessibility id for the stepper value. The `id` will be used as the accessibility id
    ///   - keyPath: A key path for updating the backing value for the stepper field.
    ///   - range: The range of allowable values for the stepper.
    ///   - title: The title of the field.
    /// - Returns: A form field for a stepper field.
    ///
    func stepperField(
        accessibilityId: String? = nil,
        keyPath: WritableKeyPath<GeneratorState, Int>,
        range: ClosedRange<Int>,
        title: String
    ) -> FormField<Self> {
        FormField(fieldType: .stepper(
            StepperField(
                accessibilityId: accessibilityId,
                keyPath: keyPath,
                range: range,
                title: title,
                value: self[keyPath: keyPath]
            )
        ))
    }

    /// A helper method for creating a text field.
    ///
    /// - Parameters:
    ///   - accessibilityId: The accessibility id for the text field.
    ///   - autocapitalization: The behavior for when the input should be automatically capitalized.
    ///     Defaults to `.never`.
    ///   - isAutocorrectDisabled: Whether autocorrect is disabled in the text field. Defaults to
    ///     `true`.
    ///   - isPasswordVisibleKeyPath: A key path for updating whether a password displayed in the
    ///     text field is visible.
    ///   - keyboardType: The type of keyboard to display.
    ///   - keyPath: A key path for getting and setting the backing value for the field.
    ///   - passwordVisibilityAccessibilityId: The accessibility id for the password visibility button.
    ///   - textContentType: The expected type of content input in the text field. Defaults to `nil`.
    ///   - title: The title of the field.
    /// - Returns: A form field for a generated value field.
    ///
    func textField(
        accessibilityId: String? = nil,
        autocapitalization: FormTextField<Self>.Autocapitalization = .never,
        isAutocorrectDisabled: Bool = true,
        isPasswordVisibleKeyPath: WritableKeyPath<GeneratorState, Bool>? = nil,
        keyboardType: UIKeyboardType = .default,
        keyPath: WritableKeyPath<GeneratorState, String>,
        passwordVisibilityAccessibilityId: String? = nil,
        textContentType: UITextContentType? = nil,
        title: String
    ) -> FormField<Self> {
        FormField(fieldType: .text(
            FormTextField(
                accessibilityId: accessibilityId,
                autocapitalization: autocapitalization,
                isAutocorrectDisabled: isAutocorrectDisabled,
                isPasswordVisible: isPasswordVisibleKeyPath.map { self[keyPath: $0] },
                isPasswordVisibleKeyPath: isPasswordVisibleKeyPath,
                keyboardType: keyboardType,
                keyPath: keyPath,
                passwordVisibilityAccessibilityId: passwordVisibilityAccessibilityId,
                textContentType: textContentType,
                title: title,
                value: self[keyPath: keyPath]
            )
        ))
    }

    /// A helper method for creating a toggle field.
    ///
    /// - Parameters:
    ///   - accessibilityId: The accessibility id for the toggle. The `id` will be used as the accessibility id
    ///   - accessibilityLabel: The accessibility label for the toggle. The title will be used as
    ///     the accessibility label if this is `nil`.
    ///   - isDisabled: Whether the toggle is disabled.
    ///   - keyPath: A key path for getting and setting the backing value for the field.
    ///   - title: The title of the field.
    /// - Returns: A form field for a toggle field.
    ///
    func toggleField(
        accessibilityId: String? = nil,
        accessibilityLabel: String? = nil,
        isDisabled: Bool = false,
        keyPath: WritableKeyPath<GeneratorState, Bool>,
        title: String
    ) -> FormField<Self> {
        FormField(fieldType: .toggle(
            ToggleField(
                accessibilityId: accessibilityId,
                accessibilityLabel: accessibilityLabel,
                isDisabled: isDisabled,
                isOn: self[keyPath: keyPath],
                keyPath: keyPath,
                title: title
            )
        ))
    }
}
