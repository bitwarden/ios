/// Actions that can be processed by a `GeneratorProcessor`.
///
enum GeneratorAction: Equatable {
    /// The copy generated value button was pressed.
    case copyGeneratedValue

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
