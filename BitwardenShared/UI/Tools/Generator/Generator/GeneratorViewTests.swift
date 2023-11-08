import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class GeneratorViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<GeneratorState, GeneratorAction, Void>!
    var subject: GeneratorView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: GeneratorState())
        let store = Store(processor: processor)

        subject = GeneratorView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping on the copy button dispatches the `.copyGeneratedValue` action.
    func test_generatedValue_copyTap() throws {
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyPassword)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyGeneratedValue)
    }

    /// Tapping on the refresh button dispatches the `.refreshGeneratedValue` action.
    func test_generatedValue_refreshTap() throws {
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.generatePassword)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .refreshGeneratedValue)
    }

    /// Updating the generator type dispatches the `.generatorTypeChanged` action.
    func test_menuGeneratorTypeChanged() throws {
        processor.state.generatorType = .password
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.whatWouldYouLikeToGenerate)
        try menuField.select(newValue: GeneratorState.GeneratorType.username)
        XCTAssertEqual(processor.dispatchedActions.last, .generatorTypeChanged(.username))
    }

    /// Updating the password generator type dispatches the `.passwordGeneratorTypeChanged` action.
    func test_menuPasswordGeneratorTypeChanged() throws {
        processor.state.passwordState.passwordGeneratorType = .password
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.passwordType)
        try menuField.select(newValue: GeneratorState.PasswordState.PasswordGeneratorType.passphrase)
        XCTAssertEqual(processor.dispatchedActions.last, .passwordGeneratorTypeChanged(.passphrase))
    }

    /// Updating the slider value dispatches the `.sliderValueChanged` action.
    func test_sliderValueChanged() throws {
        let field = SliderField<GeneratorState>(
            keyPath: \.passwordState.lengthDouble,
            range: 5 ... 128,
            step: 1,
            title: Localizations.length,
            value: 14
        )
        let slider = try subject.inspect().find(sliderWithAccessibilityLabel: Localizations.length)
        try slider.setValue(0.25) // (128 - 5 + 1) * 0.25 + 5 = 36
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .sliderValueChanged(field: field, value: 36)
        )
    }

    /// Updating the stepper value dispatches the `.stepperValueChanged` action.
    func test_stepperValueChanged() throws {
        let field = StepperField<GeneratorState>(
            keyPath: \.passwordState.minimumNumber,
            range: 0 ... 5,
            title: Localizations.minNumbers,
            value: 1
        )
        let stepper = try subject.inspect().find(ViewType.Stepper.self)
        try stepper.increment()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .stepperValueChanged(field: field, value: 2)
        )
    }

    /// Updating the text value dispatches the `.textValueChanged` action.
    func test_textValueChanged() throws {
        processor.state.passwordState.passwordGeneratorType = .passphrase
        let field = FormTextField<GeneratorState>(
            autocapitalization: .never,
            keyPath: \.passwordState.wordSeparator,
            title: Localizations.wordSeparator,
            value: "-"
        )
        let textField = try subject.inspect().find(textField: "")
        try textField.setInput("!!")
        XCTAssertEqual(processor.dispatchedActions.last, .textValueChanged(field: field, value: "!!"))
    }

    /// Updating the toggle value dispatches the `.toggleValueChanged()` action.
    func test_toggleField_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let field = ToggleField<GeneratorState>(
            accessibilityLabel: Localizations.lowercaseAtoZ,
            isOn: true,
            keyPath: \.passwordState.containsLowercase,
            title: "a-z"
        )
        let toggle = try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.lowercaseAtoZ)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleValueChanged(field: field, isOn: false))
    }

    // MARK: Snapshots

    /// Test a snapshot of the passphrase generation view.
    func test_snapshot_generatorViewPassphrase() {
        processor.state.passwordState.passwordGeneratorType = .passphrase
        assertSnapshot(
            matching: subject,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the password generation view.
    func test_snapshot_generatorViewPassword() {
        processor.state.passwordState.passwordGeneratorType = .password
        assertSnapshot(
            matching: subject,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the plus addressed username generation view.
    func test_snapshot_generatorViewUsernamePlusAddressed() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .plusAddressedEmail
        assertSnapshot(
            matching: subject,
            as: .defaultPortrait
        )
    }
}
