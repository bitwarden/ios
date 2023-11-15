import BitwardenSdk
import XCTest

@testable import BitwardenShared

class GeneratorProcessorTests: BitwardenTestCase {
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

    /// `receive(_:)` with `.appeared` generates a new generated value.
    func test_receive_appear() {
        subject.state.generatorType = .password
        subject.state.passwordState.passwordGeneratorType = .password

        subject.receive(.appeared)

        waitFor { generatorRepository.passwordGeneratorRequest != nil }
        XCTAssertNotNil(generatorRepository.passwordGeneratorRequest)
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

    /// `receive(_:)` with `.generatorTypeChanged` updates the state's generator type value.
    func test_receive_generatorTypeChanged() {
        subject.receive(.generatorTypeChanged(.password))
        XCTAssertEqual(subject.state.generatorType, .password)

        subject.receive(.generatorTypeChanged(.username))
        XCTAssertEqual(subject.state.generatorType, .username)
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

    /// `receive(_:)` with `.passwordGeneratorTypeChanged` updates the state's password generator type value.
    func test_receive_passwordGeneratorTypeChanged() {
        subject.receive(.passwordGeneratorTypeChanged(.password))
        XCTAssertEqual(subject.state.passwordState.passwordGeneratorType, .password)

        subject.receive(.passwordGeneratorTypeChanged(.passphrase))
        XCTAssertEqual(subject.state.passwordState.passwordGeneratorType, .passphrase)
    }

    /// `receive(_:)` with `.showPasswordHistory` asks the coordinator to show the password history.
    func test_receive_showPasswordHistory() {
        subject.receive(.showPasswordHistory)

        XCTAssertEqual(coordinator.routes.last, .generatorHistory)
    }

    /// `receive(_:)` with `.sliderValueChanged` updates the state's value for the slider field.
    func test_receive_sliderValueChanged() {
        let field = SliderField<GeneratorState>(
            keyPath: \.passwordState.lengthDouble,
            range: 5 ... 128,
            step: 1,
            title: Localizations.length,
            value: 14
        )

        subject.receive(.sliderValueChanged(field: field, value: 10))
        XCTAssertEqual(subject.state.passwordState.length, 10)

        subject.receive(.sliderValueChanged(field: field, value: 30))
        XCTAssertEqual(subject.state.passwordState.length, 30)
    }

    /// `receive(_:)` with `.stepperValueChanged` updates the state's value for the stepper field.
    func test_receive_stepperValueChanged() {
        let field = StepperField<GeneratorState>(
            keyPath: \.passwordState.minimumNumber,
            range: 0 ... 5,
            title: Localizations.minNumbers,
            value: 1
        )

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
        let field = FormTextField<GeneratorState>(
            keyPath: \.passwordState.wordSeparator,
            title: Localizations.wordSeparator,
            value: "-"
        )

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
        let field = ToggleField<GeneratorState>(
            accessibilityLabel: Localizations.lowercaseAtoZ,
            isOn: true,
            keyPath: \.passwordState.containsLowercase,
            title: "a-z"
        )

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
}
