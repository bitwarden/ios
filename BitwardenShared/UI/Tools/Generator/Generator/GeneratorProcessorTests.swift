import BitwardenSdk
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

class GeneratorProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var coordinator: MockCoordinator<GeneratorRoute>!
    var generatorRepository: MockGeneratorRepository!
    var pasteboardService: MockPasteboardService!
    var subject: GeneratorProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        generatorRepository = MockGeneratorRepository()
        pasteboardService = MockPasteboardService()

        subject = GeneratorProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                generatorRepository: generatorRepository,
                pasteboardService: pasteboardService
            ),
            state: GeneratorState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        generatorRepository = nil
        pasteboardService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` generates a new generated value.
    func test_perform_appear_generatesValue() async {
        subject.state.generatorType = .password
        subject.state.passwordState.passwordGeneratorType = .password

        await subject.perform(.appeared)

        XCTAssertNotNil(generatorRepository.passwordGeneratorRequest)
    }

    /// `perform(_:)` with `.appeared` loads the password generation options and doesn't change the
    /// defaults if the options are empty.
    func test_perform_appear_loadsPasswordOptions_empty() async {
        generatorRepository.passwordGenerationOptions = PasswordGenerationOptions()

        let passwordState = subject.state.passwordState

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.passwordState, passwordState)
    }

    /// `perform(_:)` with `.appeared` loads the password generation options and updates the state
    /// based on the previously selected options.
    func test_perform_appear_loadsPasswordOptions_withValues() async {
        generatorRepository.passwordGenerationOptions = PasswordGenerationOptions(
            allowAmbiguousChar: false,
            capitalize: true,
            includeNumber: true,
            length: 30,
            lowercase: false,
            minLowercase: nil,
            minNumber: 3,
            minSpecial: 1,
            minUppercase: nil,
            number: false,
            numWords: 5,
            special: true,
            type: .passphrase,
            uppercase: false,
            wordSeparator: "*"
        )

        await subject.perform(.appeared)

        XCTAssertEqual(
            subject.state.passwordState,
            GeneratorState.PasswordState(
                passwordGeneratorType: .passphrase,
                avoidAmbiguous: true,
                containsLowercase: false,
                containsNumbers: false,
                containsSpecial: true,
                containsUppercase: false,
                length: 30,
                minimumNumber: 3,
                minimumSpecial: 1,
                capitalize: true,
                includeNumber: true,
                numberOfWords: 5,
                wordSeparator: "*"
            )
        )
    }

    /// `receive(_:)` with `.copyGeneratedValue` copies the generated password to the system
    /// pasteboard and shows a toast.
    func test_receive_copiedGeneratedValue_password() {
        subject.state.generatorType = .password
        subject.state.passwordState.passwordGeneratorType = .password

        subject.state.generatedValue = "PASSWORD"
        subject.receive(.copyGeneratedValue)
        XCTAssertEqual(pasteboardService.copiedString, "PASSWORD")
        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.password))
    }

    /// `receive(_:)` with `.copyGeneratedValue` copies the generated passphrase to the system
    /// pasteboard and shows a toast.
    func test_receive_copiedGeneratedValue_passphrase() {
        subject.state.generatorType = .password
        subject.state.passwordState.passwordGeneratorType = .passphrase

        subject.state.generatedValue = "PASSPHRASE"
        subject.receive(.copyGeneratedValue)
        XCTAssertEqual(pasteboardService.copiedString, "PASSPHRASE")
        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.passphrase))
    }

    /// `receive(_:)` with `.copyGeneratedValue` copies the generated username to the system
    /// pasteboard and shows a toast.
    func test_receive_copiedGeneratedValue_username() {
        subject.state.generatorType = .username

        subject.state.generatedValue = "USERNAME"
        subject.receive(.copyGeneratedValue)
        XCTAssertEqual(pasteboardService.copiedString, "USERNAME")
        XCTAssertEqual(subject.state.toast?.text, Localizations.valueHasBeenCopied(Localizations.username))
    }

    /// `receive(_:)` with `.dismissPressed` navigates to the `.cancel` route.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes.last, .cancel)
    }

    /// `receive(_:)` with `.generatorTypeChanged` updates the state's generator type value.
    func test_receive_generatorTypeChanged() {
        subject.receive(.generatorTypeChanged(.password))
        XCTAssertEqual(subject.state.generatorType, .password)

        subject.receive(.generatorTypeChanged(.username))
        XCTAssertEqual(subject.state.generatorType, .username)
    }

    /// `receive(_:)` with `.passwordGeneratorTypeChanged` updates the state's password generator type value.
    func test_receive_passwordGeneratorTypeChanged() {
        subject.receive(.passwordGeneratorTypeChanged(.password))
        XCTAssertEqual(subject.state.passwordState.passwordGeneratorType, .password)

        subject.receive(.passwordGeneratorTypeChanged(.passphrase))
        XCTAssertEqual(subject.state.passwordState.passwordGeneratorType, .passphrase)
    }

    /// `receive(_:)` with `.refreshGeneratedValue` generates a new passphrase.
    func test_receive_refreshGeneratedValue_passphrase() {
        subject.state.generatorType = .password
        subject.state.passwordState.passwordGeneratorType = .passphrase

        subject.receive(.refreshGeneratedValue)

        waitFor { !subject.state.generatedValue.isEmpty }

        XCTAssertEqual(
            generatorRepository.passphraseGeneratorRequest,
            PassphraseGeneratorRequest(
                numWords: 3,
                wordSeparator: "-",
                capitalize: false,
                includeNumber: false
            )
        )
        XCTAssertEqual(subject.state.generatedValue, "PASSPHRASE")
    }

    /// `receive(_:)` with `.refreshGeneratedValue` generates a new password.
    func test_receive_refreshGeneratedValue_password() {
        subject.state.generatorType = .password

        subject.receive(.refreshGeneratedValue)

        waitFor { !subject.state.generatedValue.isEmpty }

        XCTAssertEqual(
            generatorRepository.passwordGeneratorRequest,
            PasswordGeneratorRequest(
                lowercase: true,
                uppercase: true,
                numbers: true,
                special: false,
                length: 14,
                avoidAmbiguous: false,
                minLowercase: nil,
                minUppercase: nil,
                minNumber: nil,
                minSpecial: nil
            )
        )
        XCTAssertEqual(subject.state.generatedValue, "PASSWORD")
    }

    /// `receive(_:)` with `.selectButtonPressed` navigates to the `.complete` route.
    func test_receive_selectButtonPressed() {
        subject.state.generatorType = .password
        subject.state.generatedValue = "password"
        subject.receive(.selectButtonPressed)
        XCTAssertEqual(coordinator.routes.last, .complete(type: .password, value: "password"))
    }

    /// `receive(_:)` with `.refreshGeneratedValue` generates a new plus addressed email.
    func test_receive_refreshGeneratedValue_usernamePlusAddressedEmail() {
        subject.state.generatorType = .username
        subject.state.usernameState.usernameGeneratorType = .plusAddressedEmail
        subject.state.usernameState.email = "user@bitwarden.com"

        subject.receive(.refreshGeneratedValue)

        waitFor { !subject.state.generatedValue.isEmpty }

        XCTAssertEqual(generatorRepository.usernamePlusAddressEmail, "user@bitwarden.com")
        XCTAssertEqual(subject.state.generatedValue, "user+abcd0123@bitwarden.com")
    }

    /// `receive(_:)` with `.showPasswordHistory` asks the coordinator to show the password history.
    func test_receive_showPasswordHistory() {
        subject.receive(.showPasswordHistory)

        XCTAssertEqual(coordinator.routes.last, .generatorHistory)
    }

    /// `receive(_:)` with `.sliderValueChanged` updates the state's value for the slider field.
    func test_receive_sliderValueChanged() {
        let field = sliderField(keyPath: \.passwordState.lengthDouble)

        subject.receive(.sliderValueChanged(field: field, value: 10))
        XCTAssertEqual(subject.state.passwordState.length, 10)

        subject.receive(.sliderValueChanged(field: field, value: 30))
        XCTAssertEqual(subject.state.passwordState.length, 30)
    }

    /// `receive(_:)` with `.stepperValueChanged` updates the state's value for the stepper field.
    func test_receive_stepperValueChanged() {
        let field = stepperField(keyPath: \.passwordState.minimumNumber)

        subject.receive(.stepperValueChanged(field: field, value: 3))
        XCTAssertEqual(subject.state.passwordState.minimumNumber, 3)

        subject.receive(.stepperValueChanged(field: field, value: 5))
        XCTAssertEqual(subject.state.passwordState.minimumNumber, 5)
    }

    /// `receive(_:)` with `.textFieldFocusChanged` updates the processor's focused key path value
    /// which is used to determine if a new value should be generated as the text field value changes.
    func test_receive_textFieldFocusChanged() {
        let field = FormTextField<GeneratorState>(
            keyPath: \.usernameState.email,
            title: Localizations.email,
            value: "user@"
        )

        subject.state.generatorType = .username
        subject.state.usernameState.usernameGeneratorType = .plusAddressedEmail

        subject.receive(.textFieldFocusChanged(keyPath: \.usernameState.email))
        subject.receive(.textValueChanged(field: field, value: "user@bitwarden.com"))
        XCTAssertNil(generatorRepository.usernamePlusAddressEmail)

        subject.receive(.textFieldFocusChanged(keyPath: nil))
        waitFor { !subject.state.generatedValue.isEmpty }
        XCTAssertEqual(generatorRepository.usernamePlusAddressEmail, "user@bitwarden.com")
        XCTAssertEqual(subject.state.generatedValue, "user+abcd0123@bitwarden.com")
    }

    /// `receive(_:)` with `.textFieldIsPasswordVisibleChanged` updates the states value for whether
    /// the password is visible for the field.
    func test_receive_textFieldIsPasswordVisibleChanged() {
        let field = FormTextField<GeneratorState>(
            isPasswordVisible: false,
            isPasswordVisibleKeyPath: \.usernameState.isAPIKeyVisible,
            keyPath: \.usernameState.addyIOAPIAccessToken,
            title: Localizations.apiAccessToken,
            value: ""
        )

        subject.state.generatorType = .username
        subject.state.usernameState.usernameGeneratorType = .forwardedEmail

        subject.receive(.textFieldIsPasswordVisibleChanged(field: field, value: true))
        XCTAssertTrue(subject.state.usernameState.isAPIKeyVisible)

        subject.receive(.textFieldIsPasswordVisibleChanged(field: field, value: false))
        XCTAssertFalse(subject.state.usernameState.isAPIKeyVisible)
    }

    /// `receive(_:)` with `.textValueChanged` updates the state's value for the text field.
    func test_receive_textValueChanged() {
        let field = textField(keyPath: \.passwordState.wordSeparator)

        subject.receive(.textValueChanged(field: field, value: "*"))
        XCTAssertEqual(subject.state.passwordState.wordSeparator, "*")

        subject.receive(.textValueChanged(field: field, value: "!"))
        XCTAssertEqual(subject.state.passwordState.wordSeparator, "!")
    }

    /// `receive(_:)` with `.textValueChanged` for the word separator limits the value to one character.
    func test_receive_textValueChanged_wordSeparatorLimitedToOneCharacter() {
        let field = FormTextField<GeneratorState>(
            keyPath: \.passwordState.wordSeparator,
            title: Localizations.wordSeparator,
            value: "-"
        )

        subject.receive(.textValueChanged(field: field, value: "-*"))
        XCTAssertEqual(subject.state.passwordState.wordSeparator, "-")

        subject.receive(.textValueChanged(field: field, value: "abc"))
        XCTAssertEqual(subject.state.passwordState.wordSeparator, "a")
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.toggleValueChanged` updates the state's value for the toggle field.
    func test_receive_toggleValueChanged() {
        let field = toggleField(keyPath: \.passwordState.containsLowercase)

        subject.receive(.toggleValueChanged(field: field, isOn: true))
        XCTAssertTrue(subject.state.passwordState.containsLowercase)

        subject.receive(.toggleValueChanged(field: field, isOn: false))
        XCTAssertFalse(subject.state.passwordState.containsLowercase)
    }

    /// `receive(_:)` with `.usernameForwardedEmailServiceChanged` updates the state's username
    /// forwarded email service value.
    func test_receive_usernameForwardedEmailServiceChanged() {
        subject.receive(.usernameForwardedEmailServiceChanged(.duckDuckGo))
        XCTAssertEqual(subject.state.usernameState.forwardedEmailService, .duckDuckGo)

        subject.receive(.usernameForwardedEmailServiceChanged(.simpleLogin))
        XCTAssertEqual(subject.state.usernameState.forwardedEmailService, .simpleLogin)
    }

    /// `receive(_:)` with `.usernameGeneratorTypeChanged` updates the state's username generator type value.
    func test_receive_usernameGeneratorTypeChanged() {
        subject.receive(.usernameGeneratorTypeChanged(.plusAddressedEmail))
        XCTAssertEqual(subject.state.usernameState.usernameGeneratorType, .plusAddressedEmail)

        subject.receive(.usernameGeneratorTypeChanged(.catchAllEmail))
        XCTAssertEqual(subject.state.usernameState.usernameGeneratorType, .catchAllEmail)
    }

    /// The user's password options are saved when any of the password options are changed.
    func test_saveGeneratorOptions_password() {
        subject.receive(.passwordGeneratorTypeChanged(.passphrase))
        waitFor { generatorRepository.passwordGenerationOptions.type == .passphrase }
        XCTAssertEqual(
            generatorRepository.passwordGenerationOptions,
            PasswordGenerationOptions(
                allowAmbiguousChar: true,
                capitalize: false,
                includeNumber: false,
                length: 14,
                lowercase: true,
                minLowercase: nil,
                minNumber: 1,
                minSpecial: 1,
                minUppercase: nil,
                number: true,
                numWords: 3,
                special: false,
                type: .passphrase,
                uppercase: true,
                wordSeparator: "-"
            )
        )

        subject.receive(.sliderValueChanged(field: sliderField(keyPath: \.passwordState.lengthDouble), value: 30))
        waitFor { generatorRepository.passwordGenerationOptions.length == 30 }
        XCTAssertEqual(generatorRepository.passwordGenerationOptions.length, 30)

        subject.receive(.stepperValueChanged(field: stepperField(keyPath: \.passwordState.minimumNumber), value: 4))
        waitFor { generatorRepository.passwordGenerationOptions.minNumber == 4 }
        XCTAssertEqual(generatorRepository.passwordGenerationOptions.minNumber, 4)

        subject.receive(.textValueChanged(field: textField(keyPath: \.passwordState.wordSeparator), value: "$"))
        waitFor { generatorRepository.passwordGenerationOptions.wordSeparator == "$" }
        XCTAssertEqual(generatorRepository.passwordGenerationOptions.wordSeparator, "$")

        subject.receive(.toggleValueChanged(
            field: toggleField(keyPath: \.passwordState.containsLowercase),
            isOn: false
        ))
        waitFor { generatorRepository.passwordGenerationOptions.lowercase == false }
        XCTAssertEqual(generatorRepository.passwordGenerationOptions.lowercase, false)
    }

    // MARK: Private

    /// Creates a `SliderField` with the specified key path.
    private func sliderField(keyPath: WritableKeyPath<GeneratorState, Double>) -> SliderField<GeneratorState> {
        SliderField<GeneratorState>(
            keyPath: keyPath,
            range: 5 ... 128,
            step: 1,
            title: Localizations.length,
            value: 14
        )
    }

    /// Creates a `StepperField` with the specified key path.
    private func stepperField(keyPath: WritableKeyPath<GeneratorState, Int>) -> StepperField<GeneratorState> {
        StepperField<GeneratorState>(
            keyPath: keyPath,
            range: 0 ... 5,
            title: Localizations.minNumbers,
            value: 1
        )
    }

    /// Creates a `FormTextField` with the specified key path.
    private func textField(keyPath: WritableKeyPath<GeneratorState, String>) -> FormTextField<GeneratorState> {
        FormTextField<GeneratorState>(
            keyPath: keyPath,
            title: Localizations.wordSeparator,
            value: "-"
        )
    }

    /// Creates a `ToggleField` with the specified key path.
    private func toggleField(keyPath: WritableKeyPath<GeneratorState, Bool>) -> ToggleField<GeneratorState> {
        ToggleField<GeneratorState>(
            accessibilityLabel: Localizations.lowercaseAtoZ,
            isOn: true,
            keyPath: keyPath,
            title: "a-z"
        )
    }
}
