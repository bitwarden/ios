/// An object that defines the current state of a `GeneratorView`.
///
struct GeneratorState: Equatable {
    // MARK: Types

    /// The type of value to generate.
    ///
    enum GeneratorType: CaseIterable, Equatable, Menuable {
        /// Generate a password or passphrase.
        case password

        /// Generate a username.
        case username

        /// All of the cases to show in the menu.
        static let allCases: [Self] = [.password, .username]

        var localizedName: String {
            switch self {
            case .password:
                return Localizations.password
            case .username:
                return Localizations.username
            }
        }
    }

    // MARK: Properties

    /// The type of value to generate.
    var generatorType = GeneratorType.password

    /// The generated value (password, passphrase or username).
    var generatedValue: String = ""

    /// The options used to generate a password.
    var passwordState = PasswordState()

    /// The options used to generate a username.
    var usernameState = UsernameState()

    // MARK: Computed Properties

    /// The list of sections to display in the generator form.
    var formSections: [FormSection<Self>] {
        var optionFields: [FormField<Self>]
        switch generatorType {
        case .password:
            switch passwordState.passwordGeneratorType {
            case .passphrase:
                optionFields = [
                    passwordGeneratorTypeField(),
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
                    passwordGeneratorTypeField(),
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
            optionFields = [
                FormField(fieldType: .menuUsernameGeneratorType(FormMenuField(
                    keyPath: \.usernameState.usernameGeneratorType,
                    options: UsernameState.UsernameGeneratorType.allCases,
                    selection: usernameState.usernameGeneratorType,
                    title: Localizations.usernameType
                ))),
            ]

            switch usernameState.usernameGeneratorType {
            case .catchAllEmail:
                break
            case .forwardedEmail:
                break
            case .plusAddressedEmail:
                optionFields.append(contentsOf: [
                    textField(
                        keyPath: \.usernameState.email,
                        title: Localizations.emailRequiredParenthesis
                    ),
                ])
            case .randomWord:
                break
            }
        }

        return [
            FormSection(
                fields: [
                    generatedValueField(keyPath: \.generatedValue),
                    FormField(fieldType: .menuGeneratorType(FormMenuField(
                        keyPath: \.generatorType,
                        options: GeneratorType.allCases,
                        selection: generatorType,
                        title: Localizations.whatWouldYouLikeToGenerate
                    ))),
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
