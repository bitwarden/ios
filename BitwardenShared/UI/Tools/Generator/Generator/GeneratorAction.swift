/// Actions that can be processed by a `GeneratorProcessor`.
///
enum GeneratorAction: Equatable {
    /// The generator view appeared on screen.
    case appeared

    /// The copy generated value button was pressed.
    case copyGeneratedValue

    /// The generator type was changed.
    case generatorTypeChanged(GeneratorState.GeneratorType)

    /// The password generator type was changed.
    case passwordGeneratorTypeChanged(GeneratorState.PasswordState.PasswordGeneratorType)

    /// The refresh generated value button was pressed.
    case refreshGeneratedValue

    /// A slider field value was changed.
    case sliderValueChanged(field: SliderField<GeneratorState>, value: Double)

    /// A stepper field value was changed.
    case stepperValueChanged(field: StepperField<GeneratorState>, value: Int)

    /// A text field value was changed.
    case textValueChanged(field: FormTextField<GeneratorState>, value: String)

    /// A toggle field value was changed.
    case toggleValueChanged(field: ToggleField<GeneratorState>, isOn: Bool)

    /// The username generator type was changed.
    case usernameGeneratorTypeChanged(GeneratorState.UsernameState.UsernameGeneratorType)
}

extension GeneratorAction {
    // MARK: Computed Properties

    /// Whether this action should result in the processor generating a new generated value.
    var shouldGenerateNewValue: Bool {
        switch self {
        case .appeared,
             .generatorTypeChanged,
             .passwordGeneratorTypeChanged,
             .refreshGeneratedValue,
             .sliderValueChanged,
             .stepperValueChanged,
             .textValueChanged,
             .toggleValueChanged,
             .usernameGeneratorTypeChanged:
            return true
        case .copyGeneratedValue:
            return false
        }
    }
}
