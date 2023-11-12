import BitwardenSdk
import XCTest

@testable import BitwardenShared

class GeneratorProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<GeneratorRoute>!
    var generatorRepository: MockGeneratorRepository!
    var subject: GeneratorProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        generatorRepository = MockGeneratorRepository()

        subject = GeneratorProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                generatorRepository: generatorRepository
            ),
            state: GeneratorState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        generatorRepository = nil
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

        waitFor { generatorRepository.passphraseGeneratorRequest != nil }

        XCTAssertEqual(
            generatorRepository.passphraseGeneratorRequest,
            PassphraseGeneratorRequest(
                numWords: 3,
                wordSeparator: "-",
                capitalize: false,
                includeNumber: false
            )
        )
    }

    /// `receive(_:)` with `.refreshGeneratedValue` generates a new password.
    func test_receive_refreshGeneratedValue_password() {
        subject.state.generatorType = .password

        subject.receive(.refreshGeneratedValue)

        waitFor { generatorRepository.passwordGeneratorRequest != nil }
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
    }

    /// `receive(_:)` with `.selectButtonPressed` navigates to the `.complete` route.
    func test_receive_selectButtonPressed() {
        subject.state.generatorType = .password
        subject.state.generatedValue = "password"
        subject.receive(.selectButtonPressed)
        XCTAssertEqual(coordinator.routes.last, .complete(type: .password, value: "password"))
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

    /// `receive(_:)` with `.usernameGeneratorTypeChanged` updates the state's username generator type value.
    func test_receive_usernameGeneratorTypeChanged() {
        subject.receive(.usernameGeneratorTypeChanged(.plusAddressedEmail))
        XCTAssertEqual(subject.state.usernameState.usernameGeneratorType, .plusAddressedEmail)

        subject.receive(.usernameGeneratorTypeChanged(.catchAllEmail))
        XCTAssertEqual(subject.state.usernameState.usernameGeneratorType, .catchAllEmail)
    }
}
