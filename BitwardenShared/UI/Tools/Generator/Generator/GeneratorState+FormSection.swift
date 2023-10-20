extension GeneratorState {
    /// Data model containing the data to display a section of fields in a form.
    ///
    struct FormSection<State>: Equatable, Identifiable {
        // MARK: Properties

        /// The list of fields to display in the section.
        let fields: [FormField<State>]

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
            /// A generated value field.
            case generatedValue(GeneratedValueField<State>)

            /// A picker field.
            case picker(PickerField<State>)

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
                case let .generatedValue(field):
                    return field.id
                case let .picker(field):
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

    /// The data necessary for displaying a picker field.
    ///
    struct PickerField<State>: Equatable, Identifiable {
        // MARK: Properties

        /// A key path for updating the backing value for the picker field.
        var keyPath: WritableKeyPath<State, String>

        /// The title of the field.
        var title: String

        /// The current picker value.
        var value: String

        // MARK: Identifiable

        var id: String {
            "PickerField-\(title)"
        }
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

    /// A helper method for creating a picker field.
    ///
    /// - Parameters:
    ///   - keyPath: A key path for getting and setting the backing value for the field.
    ///   - title: The title of the field.
    /// - Returns: A form field for a picker field.
    ///
    func pickerField(keyPath: WritableKeyPath<GeneratorState, String>, title: String) -> FormField<Self> {
        FormField(fieldType: .picker(
            PickerField(
                keyPath: keyPath,
                title: title,
                value: self[keyPath: keyPath]
            ))
        )
    }

    /// A helper method for creating a slider field.
    ///
    /// - Parameters:
    ///   - keyPath: A key path for getting and setting the backing value for the field.
    ///   - range: The range of allowable values for the slider.
    ///   - title: The title of the field.
    ///   - step: The distance between each valid value.
    /// - Returns: A form field for a slider field.
    ///
    func sliderField(
        keyPath: WritableKeyPath<GeneratorState, Double>,
        range: ClosedRange<Double>,
        title: String,
        step: Double
    ) -> FormField<Self> {
        FormField(fieldType: .slider(
            SliderField(
                keyPath: keyPath,
                range: range,
                step: step,
                title: title,
                value: self[keyPath: keyPath]
            )
        ))
    }

    /// A helper method for creating a stepper field.
    ///
    /// - Parameters:
    ///   - keyPath: A key path for updating the backing value for the stepper field.
    ///   - range: The range of allowable values for the stepper.
    ///   - title: The title of the field.
    /// - Returns: A form field for a stepper field.
    ///
    func stepperField(
        keyPath: WritableKeyPath<GeneratorState, Int>,
        range: ClosedRange<Int>,
        title: String
    ) -> FormField<Self> {
        FormField(fieldType: .stepper(
            StepperField(
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
    ///   - autocapitalization: The behavior for when the input should be automatically capitalized.
    ///   - keyPath: A key path for getting and setting the backing value for the field.
    ///   - title: The title of the field.
    /// - Returns: A form field for a generated value field.
    ///
    func textField(
        autocapitalization: FormTextField<Self>.Autocapitalization,
        keyPath: WritableKeyPath<GeneratorState, String>,
        title: String
    ) -> FormField<Self> {
        FormField(fieldType: .text(
            FormTextField(
                autocapitalization: autocapitalization,
                keyPath: keyPath,
                title: title,
                value: self[keyPath: keyPath]
            )
        ))
    }

    /// A helper method for creating a toggle field.
    ///
    /// - Parameters:
    ///   - accessibilityLabel: The accessibility label for the toggle. The title will be used as
    ///     the accessibility label if this is `nil`.
    ///   - keyPath: A key path for getting and setting the backing value for the field.
    ///   - title: The title of the field.
    /// - Returns: A form field for a toggle field.
    ///
    func toggleField(
        accessibilityLabel: String? = nil,
        keyPath: WritableKeyPath<GeneratorState, Bool>,
        title: String
    ) -> FormField<Self> {
        FormField(fieldType: .toggle(
            ToggleField(
                accessibilityLabel: accessibilityLabel,
                isOn: self[keyPath: keyPath],
                keyPath: keyPath,
                title: title
            )
        ))
    }
}
