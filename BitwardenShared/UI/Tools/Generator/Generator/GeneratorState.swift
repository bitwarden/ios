import BitwardenResources

// swiftlint:disable file_length

// MARK: - GeneratorType

/// The type of value to generate.
///
public enum GeneratorType: CaseIterable, Equatable, Identifiable, Menuable, Sendable {
    /// Generate a passphrase.
    case passphrase

    /// Generate a password.
    case password

    /// Generate a username.
    case username

    /// All of the cases to show in the menu.
    public static let allCases: [Self] = [.password, .passphrase, .username]

    public var id: String {
        localizedName
    }

    var localizedName: String {
        switch self {
        case .passphrase:
            return Localizations.passphrase
        case .password:
            return Localizations.password
        case .username:
            return Localizations.username
        }
    }
}

// MARK: - GeneratorState

/// An object that defines the current state of a `GeneratorView`.
///
struct GeneratorState: Equatable {
    // MARK: Types

    /// The presentation mode for the generator. Used to determine if specific UI elements are shown.
    enum PresentationMode: Equatable {
        /// The generator is being presented in its own tab for a generic generation task.
        case tab

        /// The generator is being presented in place for a specific generation task.
        case inPlace

        /// A flag indicating if the dismiss button is visible.
        var isDismissButtonVisible: Bool {
            switch self {
            case .tab: false
            case .inPlace: true
            }
        }

        /// A flag indicating if the options toolbar button is visible.
        var isOptionsButtonVisible: Bool {
            switch self {
            case .tab: true
            case .inPlace: false
            }
        }

        /// A flag indicating if the select button is visible.
        var isSelectButtonVisible: Bool {
            switch self {
            case .tab: false
            case .inPlace: true
            }
        }
    }

    // MARK: Properties

    /// The type of value to generate.
    var generatorType = GeneratorType.password

    /// The generated value (password, passphrase or username).
    var generatedValue: String = ""

    /// The state of the guided tour view.
    var guidedTourViewState = GuidedTourViewState(
        guidedTourStepStates: [
            .generatorStep1,
            .generatorStep2,
            .generatorStep3,
            .generatorStep4,
            .generatorStep5,
            .generatorStep6,
        ]
    )

    /// If account is eligible for learn generator action card.
    var isLearnGeneratorActionCardEligible: Bool = false

    /// Whether there's a password generation policy in effect.
    var isPolicyInEffect = false

    /// The options used to generate a password.
    var passwordState = PasswordState()

    /// The policy options in effect.
    var policyOptions: PasswordGenerationOptions?

    /// The mode the generator is currently in. This value determines if the UI should show specific
    /// elements.
    var presentationMode: PresentationMode = .tab

    /// A toast message to show in the view.
    var toast: Toast?

    /// The options used to generate a username.
    var usernameState = UsernameState()

    // MARK: Computed Properties

    /// The list of available generator types that should be shown in the segmented control.
    var availableGeneratorTypes: [GeneratorType] {
        switch presentationMode {
        case .tab:
            GeneratorType.allCases
        case .inPlace:
            switch generatorType {
            case .passphrase, .password:
                [.password, .passphrase]
            case .username:
                []
            }
        }
    }

    /// The list of sections to display in the generator form.
    var formSections: [FormSection<Self>] {
        let generatorGroup = FormSectionGroup(
            fields: [generatedValueField(keyPath: \.generatedValue)],
            id: "GeneratorGroup",
            showInContentBlock: false
        )

        let optionGroups: [FormSectionGroup<Self>] = switch generatorType {
        case .passphrase:
            passphraseFormFields
        case .password:
            passwordFormFields
        case .username:
            usernameFormFields
        }

        return [
            FormSection(
                groups: [generatorGroup],
                id: "Generator",
                title: nil
            ),

            FormSection<Self>(
                groups: optionGroups,
                id: "Generator Options",
                title: Localizations.options
            ),
        ]
    }

    // MARK: Methods

    /// Returns whether the specified `GeneratorType` should be disabled from user selection.
    ///
    /// - Parameter generatorType: The `GeneratorType` to determine if it's disabled.
    /// - Returns: `true` if the generator type is disabled, or `false` otherwise.
    ///
    func isGeneratorTypeDisabled(_ generatorType: GeneratorType) -> Bool {
        guard policyOptions?.overridePasswordType == true, generatorType != .username else { return false }
        let overrideType = policyOptions?.type?.generatorType ?? .password
        return generatorType != overrideType
    }

    /// Sets the generator type based on the stored password generator type.
    ///
    /// - Parameter passwordGeneratorType: The stored `PasswordGeneratorType` used to determine the
    ///     generator type or `nil` if it hasn't been previously stored.
    ///
    mutating func setGeneratorType(passwordGeneratorType: PasswordGeneratorType?) {
        // Don't switch to password or passphrase if the generator type has been toggled to username.
        guard generatorType != .username else { return }
        generatorType = passwordGeneratorType?.generatorType ?? .password
    }

    /// Returns whether changing the slider value should generate a new value.
    /// - Parameters:
    ///   - value: The updated value of the slider.
    ///   - keyPath: The key path to the field in which the slider value was changed.
    /// - Returns: `true` if a new value should be generated or `false` otherwise.
    ///
    func shouldGenerateNewValueOnSliderValueChanged(_ value: Double, keyPath: KeyPath<GeneratorState, Double>) -> Bool {
        switch keyPath {
        case \.passwordState.lengthDouble:
            guard Int(value) != passwordState.length else { return false }
            let policyMinLength = policyOptions?.length ?? 0
            return Int(value) >= max(policyMinLength, passwordState.minimumLength)
        default:
            return true
        }
    }

    /// Returns whether changing the text value should generate a new value.
    ///
    /// - Parameter keyPath: The key path to the field in which the text value was changed.
    /// - Returns: `true` if a new value should be generated or `false` otherwise.
    ///
    func shouldGenerateNewValueOnTextValueChanged(keyPath: KeyPath<GeneratorState, String>) -> Bool {
        switch keyPath {
        case \.passwordState.wordSeparator:
            true
        default:
            // For most text fields, wait until focus leaves the field before generating a new value.
            false
        }
    }

    /// Updates the state to show a toast for the value that was copied.
    ///
    mutating func showCopiedValueToast() {
        let valueCopied: String
        switch generatorType {
        case .passphrase:
            valueCopied = Localizations.passphrase
        case .password:
            valueCopied = Localizations.password
        case .username:
            valueCopied = Localizations.username
        }
        toast = Toast(title: Localizations.valueHasBeenCopied(valueCopied))
    }
}

extension GeneratorState {
    /// Returns the list of fields for the passphrase generator.
    ///
    var passphraseFormFields: [FormSectionGroup<Self>] {
        [
            FormSectionGroup(
                fields: [
                    stepperField(
                        accessibilityId: "NumberOfWordsStepper",
                        keyPath: \.passwordState.numberOfWords,
                        range: 3 ... 20,
                        title: Localizations.numberOfWords
                    ),
                    textField(
                        accessibilityId: "WordSeparatorEntry",
                        keyPath: \.passwordState.wordSeparator,
                        title: Localizations.wordSeparator
                    ),
                    toggleField(
                        accessibilityId: "CapitalizePassphraseToggle",
                        isDisabled: policyOptions?.capitalize != nil,
                        keyPath: \.passwordState.capitalize,
                        title: Localizations.capitalize
                    ),
                    toggleField(
                        accessibilityId: "IncludeNumbersToggle",
                        isDisabled: policyOptions?.includeNumber != nil,
                        keyPath: \.passwordState.includeNumber,
                        title: Localizations.includeNumber
                    ),
                ],
                id: "PassphraseGroup"
            ),
        ]
    }

    /// Returns the list of fields for the password generator.
    ///
    var passwordFormFields: [FormSectionGroup<Self>] {
        [
            FormSectionGroup(
                fields: [
                    sliderField(
                        keyPath: \.passwordState.lengthDouble,
                        range: 5 ... 128,
                        sliderAccessibilityId: "PasswordLengthSlider",
                        sliderValueAccessibilityId: "PasswordLengthLabel",
                        title: Localizations.length,
                        step: 1
                    ),
                    toggleField(
                        accessibilityId: "UppercaseAtoZToggle",
                        accessibilityLabel: Localizations.uppercaseAtoZ,
                        isDisabled: policyOptions?.uppercase != nil,
                        keyPath: \.passwordState.containsUppercase,
                        title: "A-Z"
                    ),
                    toggleField(
                        accessibilityId: "LowercaseAtoZToggle",
                        accessibilityLabel: Localizations.lowercaseAtoZ,
                        isDisabled: policyOptions?.lowercase != nil,
                        keyPath: \.passwordState.containsLowercase,
                        title: "a-z"
                    ),
                    toggleField(
                        accessibilityId: "NumbersZeroToNineToggle",
                        accessibilityLabel: Localizations.numbersZeroToNine,
                        isDisabled: policyOptions?.number != nil,
                        keyPath: \.passwordState.containsNumbers,
                        title: "0-9"
                    ),
                    toggleField(
                        accessibilityId: "SpecialCharactersToggle",
                        accessibilityLabel: Localizations.specialCharacters,
                        isDisabled: policyOptions?.special != nil,
                        keyPath: \.passwordState.containsSpecial,
                        title: "!@#$%^&*"
                    ),
                    stepperField(
                        accessibilityId: "MinNumberValueLabel",
                        keyPath: \.passwordState.minimumNumber,
                        range: 0 ... 5,
                        title: Localizations.minNumbers
                    ),
                    stepperField(
                        accessibilityId: "MinSpecialValueLabel",
                        keyPath: \.passwordState.minimumSpecial,
                        range: 0 ... 5,
                        title: Localizations.minSpecial
                    ),
                    toggleField(
                        accessibilityId: "AvoidAmbiguousCharsToggle",
                        keyPath: \.passwordState.avoidAmbiguous,
                        title: Localizations.avoidAmbiguousCharacters
                    ),
                ],
                id: "PasswordGroup"
            ),
        ]
    }

    /// Returns the list of fields for the username generator.
    ///
    var usernameFormFields: [FormSectionGroup<Self>] {
        var groups = [FormSectionGroup<Self>]()

        groups.append(
            FormSectionGroup(
                fields: [
                    FormField(fieldType: .menuUsernameGeneratorType(FormMenuField(
                        accessibilityIdentifier: "UsernameTypePicker",
                        footer: usernameState.usernameGeneratorType.localizedDescription,
                        keyPath: \.usernameState.usernameGeneratorType,
                        options: UsernameGeneratorType.allCases,
                        selection: usernameState.usernameGeneratorType,
                        title: Localizations.usernameType
                    ))),
                ],
                id: "UsernameTypeGroup"
            )
        )

        switch usernameState.usernameGeneratorType {
        case .catchAllEmail:
            var fields = [
                textField(
                    accessibilityId: "CatchAllEmailDomainEntry",
                    keyboardType: .URL,
                    keyPath: \.usernameState.domain,
                    textContentType: .URL,
                    title: Localizations.domainNameRequiredParenthesis
                ),
            ]

            if let emailWebsite = usernameState.emailWebsite {
                fields.append(contentsOf: [
                    emailTypeField(keyPath: \.usernameState.catchAllEmailType),
                    FormField(fieldType: .emailWebsite(emailWebsite)),
                ])
            }

            groups.append(FormSectionGroup(fields: fields, id: "CatchAllEmailGroup"))
        case .forwardedEmail:
            groups.append(
                FormSectionGroup(
                    fields: [
                        FormField(fieldType: .menuUsernameForwardedEmailService(
                            FormMenuField(
                                accessibilityIdentifier: "ServiceTypePicker",
                                keyPath: \.usernameState.forwardedEmailService,
                                options: ForwardedEmailServiceType.allCases,
                                selection: usernameState.forwardedEmailService,
                                title: Localizations.service
                            )
                        )),
                    ],
                    id: "ServiceTypeGroup"
                )
            )

            var fields = [FormField<Self>]()
            switch usernameState.forwardedEmailService {
            case .addyIO:
                fields.append(contentsOf: [
                    textField(
                        accessibilityId: "ForwardedEmailApiSecretEntry",
                        isPasswordVisibleKeyPath: \.usernameState.isAPIKeyVisible,
                        keyPath: \.usernameState.addyIOAPIAccessToken,
                        passwordVisibilityAccessibilityId: "ShowForwardedEmailApiSecretButton",
                        title: Localizations.apiAccessToken
                    ),
                    textField(
                        accessibilityId: "AnonAddyDomainNameEntry",
                        keyPath: \.usernameState.addyIODomainName,
                        title: Localizations.domainNameRequiredParenthesis
                    ),
                ])
                fields.append(contentsOf: [
                    textField(
                        accessibilityId: "AnonAddySelfHosteUrlEntry",
                        keyPath: \.usernameState.addyIOSelfHostServerUrl,
                        title: Localizations.selfHostServerURL
                    ),
                ])
            case .duckDuckGo:
                fields.append(
                    textField(
                        isPasswordVisibleKeyPath: \.usernameState.isAPIKeyVisible,
                        keyPath: \.usernameState.duckDuckGoAPIKey,
                        title: Localizations.apiKeyRequiredParenthesis
                    )
                )
            case .fastmail:
                fields.append(
                    textField(
                        isPasswordVisibleKeyPath: \.usernameState.isAPIKeyVisible,
                        keyPath: \.usernameState.fastmailAPIKey,
                        title: Localizations.apiKeyRequiredParenthesis
                    )
                )
            case .firefoxRelay:
                fields.append(
                    textField(
                        isPasswordVisibleKeyPath: \.usernameState.isAPIKeyVisible,
                        keyPath: \.usernameState.firefoxRelayAPIAccessToken,
                        title: Localizations.apiAccessToken
                    )
                )
            case .forwardEmail:
                fields.append(contentsOf: [
                    textField(
                        accessibilityId: "ForwardedEmailApiSecretEntry",
                        isPasswordVisibleKeyPath: \.usernameState.isAPIKeyVisible,
                        keyPath: \.usernameState.forwardEmailAPIToken,
                        passwordVisibilityAccessibilityId: "ShowForwardedEmailApiSecretButton",
                        title: Localizations.apiKeyRequiredParenthesis
                    ),
                    textField(
                        accessibilityId: "ForwardEmailDomainNameEntry",
                        keyPath: \.usernameState.forwardEmailDomainName,
                        title: Localizations.domainNameRequiredParenthesis
                    ),
                ])
            case .simpleLogin:
                fields.append(
                    textField(
                        isPasswordVisibleKeyPath: \.usernameState.isAPIKeyVisible,
                        keyPath: \.usernameState.simpleLoginAPIKey,
                        title: Localizations.apiKeyRequiredParenthesis
                    )
                )
                fields.append(contentsOf: [
                    textField(
                        accessibilityId: "SimpleLoginSelfHosteUrlEntry",
                        keyPath: \.usernameState.simpleLoginSelfHostServerUrl,
                        title: Localizations.selfHostServerURL
                    ),
                ])
            }

            groups.append(FormSectionGroup(fields: fields, id: "ForwardedEmailGroup"))
        case .plusAddressedEmail:
            var fields = [
                textField(
                    accessibilityId: "PlusAddressedEmailEntry",
                    keyboardType: .emailAddress,
                    keyPath: \.usernameState.email,
                    textContentType: .emailAddress,
                    title: Localizations.emailRequiredParenthesis
                ),
            ]

            if let emailWebsite = usernameState.emailWebsite {
                fields.append(contentsOf: [
                    emailTypeField(keyPath: \.usernameState.plusAddressedEmailType),
                    FormField(fieldType: .emailWebsite(emailWebsite)),
                ])
            }

            groups.append(FormSectionGroup(fields: fields, id: "PlusAddressedEmailGroup"))
        case .randomWord:
            let fields = [
                toggleField(
                    accessibilityId: "CapitalizeRandomWordUsernameToggle",
                    keyPath: \.usernameState.capitalize,
                    title: Localizations.capitalize
                ),
                toggleField(
                    accessibilityId: "IncludeNumberRandomWordUsernameToggle",
                    keyPath: \.usernameState.includeNumber,
                    title: Localizations.includeNumber
                ),
            ]
            groups.append(FormSectionGroup(fields: fields, id: "RandomWordGroup"))
        }

        return groups
    }
}

/// extension for `GuidedTourStepState` to provide states for learn generator guided tour.
extension GuidedTourStepState {
    /// The first step of the learn generator guided tour.
    static let generatorStep1 = GuidedTourStepState(
        arrowHorizontalPosition: .left,
        spotlightShape: .rectangle(cornerRadius: 25),
        title: Localizations.useTheGeneratorToCreateASecurePasswordPassphrasesAndUsernames
    )

    /// The second step of the learn generator guided tour.
    static let generatorStep2 = GuidedTourStepState(
        arrowHorizontalPosition: .center,
        spotlightShape: .rectangle(cornerRadius: 25),
        title: Localizations.passphrasesAreOftenEasierToRememberDescriptionLong
    )

    /// The third step of the learn generator guided tour.
    static let generatorStep3 = GuidedTourStepState(
        arrowHorizontalPosition: .right,
        spotlightShape: .rectangle(cornerRadius: 25),
        title: Localizations.uniqueUsernamesAddAnExtraLayerOfSecurityAndCanHelpPreventHackersFromFindingYourAccounts
    )

    /// The fourth step of the learn generator guided tour.
    static let generatorStep4 = GuidedTourStepState(
        arrowHorizontalPosition: .center,
        spotlightShape: .rectangle(cornerRadius: 8),
        title: Localizations.useTheseOptionsToAdjustYourPasswordToMeetYourAccountWebsitesRequirements
    )

    /// The fifth step of the learn generator guided tour.
    static let generatorStep5 = GuidedTourStepState(
        arrowHorizontalPosition: .center,
        spotlightShape: .circle,
        title: Localizations.useThisButtonToGenerateANewUniquePassword
    )

    /// The sixth step of the learn generator guided tour.
    static let generatorStep6 = GuidedTourStepState(
        arrowHorizontalPosition: .center,
        spotlightShape: .rectangle(cornerRadius: 8),
        title: Localizations.afterYouSaveYourNewPasswordToBitwardenDontForgetToUpdateItOnYourAccountWebsite
    )
}
