/// Actions that can be processed by a `GeneratorProcessor`.
///
enum GeneratorAction: Equatable {
    /// The copy generated value button was pressed.
    case copyGeneratedValue

    /// The dismiss button was pressed
    case dismissPressed

    /// The email type was changed.
    case emailTypeChanged(UsernameEmailType)

    /// The generator type was changed.
    case generatorTypeChanged(GeneratorType)

    /// The password generator type was changed.
    case passwordGeneratorTypeChanged(PasswordGeneratorType)

    /// The refresh generated value button was pressed.
    case refreshGeneratedValue

    /// The select button was pressed.
    case selectButtonPressed

    /// The show password history button was pressed.
    case showPasswordHistory

    /// A slider field editing value was changed.
    case sliderEditingChanged(field: SliderField<GeneratorState>, isEditing: Bool)

    /// A slider field value was changed.
    case sliderValueChanged(field: SliderField<GeneratorState>, value: Double)

    /// A stepper field value was changed.
    case stepperValueChanged(field: StepperField<GeneratorState>, value: Int)

    /// A text field was focused or lost focus.
    case textFieldFocusChanged(keyPath: KeyPath<GeneratorState, String>?)

    /// A text field's toggle for displaying or hiding the password was changed.
    case textFieldIsPasswordVisibleChanged(field: FormTextField<GeneratorState>, value: Bool)

    /// A text field value was changed.
    case textValueChanged(field: FormTextField<GeneratorState>, value: String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// A toggle field value was changed.
    case toggleValueChanged(field: ToggleField<GeneratorState>, isOn: Bool)

    /// The username forwarded email service was changed.
    case usernameForwardedEmailServiceChanged(ForwardedEmailServiceType)

    /// The username generator type was changed.
    case usernameGeneratorTypeChanged(UsernameGeneratorType)
}

extension GeneratorAction {
    // MARK: Computed Properties

    /// Whether this action should result in the processor generating a new generated value.
    var shouldGenerateNewValue: Bool {
        switch self {
        case .emailTypeChanged,
             .generatorTypeChanged,
             .passwordGeneratorTypeChanged,
             .refreshGeneratedValue,
             .stepperValueChanged,
             .textValueChanged,
             .toggleValueChanged,
             .usernameForwardedEmailServiceChanged,
             .usernameGeneratorTypeChanged:
            return true
        case let .sliderEditingChanged(_, isEditing):
            // Only generate a new value when editing completes.
            return !isEditing
        case let .textFieldFocusChanged(keyPath):
            // Only generate a new value when focus leaves the field (keyPath == nil).
            return keyPath == nil
        case .copyGeneratedValue,
             .dismissPressed,
             .selectButtonPressed,
             .showPasswordHistory,
             .sliderValueChanged,
             .textFieldIsPasswordVisibleChanged,
             .toastShown:
            return false
        }
    }
}
