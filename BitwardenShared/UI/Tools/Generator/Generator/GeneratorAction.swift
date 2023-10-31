/// Actions that can be processed by a `GeneratorProcessor`.
///
enum GeneratorAction: Equatable {
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
}
