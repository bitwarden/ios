/// An object that defines the current state of a `GeneratorView`.
///
struct GeneratorState: Equatable {
    // MARK: Types

    /// The type of value to generate.
    ///
    enum GeneratorType: String, Equatable {
        /// Generate a password or passphrase.
        case password

        /// Generate a username.
        case username

        var rawValue: String {
            switch self {
            case .password:
                return Localizations.password
            case .username:
                return Localizations.username
            }
        }

        init?(rawValue: String) {
            switch rawValue {
            case Localizations.password:
                self = .password
            case Localizations.username:
                self = .username
            default:
                return nil
            }
        }
    }

    // MARK: Properties

    /// The type of value to generate.
    var generatorType = GeneratorType.password

    /// A proxy value for getting and setting `generatorType` via key path with its raw value.
    var generatorTypeValue: String {
        get { generatorType.rawValue }
        set {
            guard let generatorType = GeneratorType(rawValue: newValue) else { return }
            self.generatorType = generatorType
        }
    }

    /// The generated value (password, passphrase or username).
    var generatedValue: String = ""

    /// The options used to generate a password.
    var passwordState = PasswordState()

    // MARK: Computed Properties

    /// The list of sections to display in the generator form.
    var formSections: [FormSection<Self>] {
        let optionFields: [FormField<Self>]
        switch generatorType {
        case .password:
            switch passwordState.passwordGeneratorType {
            case .passphrase:
                optionFields = [
                    pickerField(keyPath: \.passwordState.passwordGeneratorTypeValue, title: Localizations.passwordType),
                    stepperField(
                        keyPath: \.passwordState.numberOfWords,
                        range: 3 ... 20,
                        title: Localizations.numberOfWords
                    ),
                    textField(
                        autocapitalization: .never,
                        keyPath: \.passwordState.wordSeparator,
                        title: Localizations.wordSeparator
                    ),
                    toggleField(keyPath: \.passwordState.capitalize, title: Localizations.capitalize),
                    toggleField(keyPath: \.passwordState.includeNumber, title: Localizations.includeNumber),
                ]
            case .password:
                optionFields = [
                    pickerField(keyPath: \.passwordState.passwordGeneratorTypeValue, title: Localizations.passwordType),
                    sliderField(
                        keyPath: \.passwordState.lengthDouble,
                        range: 5 ... 128,
                        title: Localizations.length,
                        step: 1
                    ),
                    toggleField(
                        accessibilityLabel: Localizations.uppercaseAtoZ,
                        keyPath: \.passwordState.containsUppercase,
                        title: "A-Z"
                    ),
                    toggleField(
                        accessibilityLabel: Localizations.lowercaseAtoZ,
                        keyPath: \.passwordState.containsLowercase,
                        title: "a-z"
                    ),
                    toggleField(
                        accessibilityLabel: Localizations.numbersZeroToNine,
                        keyPath: \.passwordState.containsNumbers,
                        title: "0-9"
                    ),
                    toggleField(
                        accessibilityLabel: Localizations.specialCharacters,
                        keyPath: \.passwordState.containsSpecial,
                        title: "!@#$%^&*"
                    ),
                    stepperField(
                        keyPath: \.passwordState.minimumNumber,
                        range: 0 ... 5,
                        title: Localizations.minNumbers
                    ),
                    stepperField(
                        keyPath: \.passwordState.minimumSpecial,
                        range: 0 ... 5,
                        title: Localizations.minSpecial
                    ),
                    toggleField(keyPath: \.passwordState.avoidAmbiguous, title: Localizations.avoidAmbiguousCharacters),
                ]
            }
        case .username:
            optionFields = []
        }

        return [
            FormSection(
                fields: [
                    generatedValueField(keyPath: \.generatedValue),
                    pickerField(keyPath: \.generatorTypeValue, title: Localizations.whatWouldYouLikeToGenerate),
                ],
                id: "Generator",
                title: nil
            ),

            FormSection<Self>(
                fields: optionFields,
                id: "Generator Options",
                title: Localizations.options
            ),
        ]
    }
}
