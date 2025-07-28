import BitwardenResources
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

class GeneratorViewTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Types

    /// Wraps the generator view in a navigation controller with the hairline divider removed for
    /// snapshot tests.
    struct SnapshotView: UIViewControllerRepresentable {
        let subject: GeneratorView

        func makeUIViewController(context: Context) -> some UIViewController {
            let viewController = UIHostingController(rootView: subject)
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.prefersLargeTitles = true
            navigationController.removeHairlineDivider()
            return navigationController
        }

        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    }

    // MARK: Properties

    var processor: MockProcessor<GeneratorState, GeneratorAction, GeneratorEffect>!
    var subject: GeneratorView!

    var snapshotView: some View {
        SnapshotView(subject: subject).edgesIgnoringSafeArea(.all)
    }

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

    /// Tapping on the dismiss button dispatches the `.dismissPressed` action.
    @MainActor
    func test_dismissButton_tap() throws {
        processor.state.presentationMode = .inPlace
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping on the copy button dispatches the `.copyGeneratedValue` action.
    @MainActor
    func test_generatedValue_copyTap() throws {
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyPassword)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyGeneratedValue)
    }

    /// Tapping on the refresh button dispatches the `.refreshGeneratedValue` action.
    @MainActor
    func test_generatedValue_refreshTap() throws {
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.generatePassword)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .refreshGeneratedValue)
    }

    /// Tapping the dismiss button in the learn generator action card sends the
    /// `.dismissLearnGeneratorActionCard` effect.
    @MainActor
    func test_learnGeneratorActionCard_visible_tapDismiss() async throws {
        processor.state.isLearnGeneratorActionCardEligible = true
        let actionCard = try subject.inspect().find(actionCard: Localizations.exploreTheGenerator)

        let button = try actionCard.find(asyncButton: Localizations.dismiss)
        try await button.tap()
        XCTAssertEqual(processor.effects, [.dismissLearnGeneratorActionCard])
    }

    /// Tapping the 'Get started' button in the learn generator action card sends the
    /// `.showLearnNewLoginGuidedTour` effect.
    @MainActor
    func test_learnGeneratorActionCard_visible_tapGetStarted() async throws {
        processor.state.isLearnGeneratorActionCardEligible = true
        let actionCard = try subject.inspect().find(actionCard: Localizations.exploreTheGenerator)

        let button = try actionCard.find(asyncButton: Localizations.getStarted)
        try await button.tap()
        XCTAssertEqual(processor.effects, [.showLearnGeneratorGuidedTour])
    }

    /// Tests that the generator action card is not present when `.presentationMode` is `.inPlace`.
    @MainActor
    func test_learnGeneratorActionCard_inVisible() throws {
        processor.state.isLearnGeneratorActionCardEligible = true
        processor.state.presentationMode = .inPlace
        let actionCard = try? subject.inspect().find(actionCard: Localizations.exploreTheGenerator)
        XCTAssertNil(actionCard)
    }

    /// Updating the email type dispatches the `.emailTypeChanged` action.
    @MainActor
    func test_menuEmailTypeChanged() throws {
        processor.state.generatorType = .username
        processor.state.usernameState.emailWebsite = "bitwarden.com"
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.emailType)
        try menuField.select(newValue: UsernameEmailType.website)
        XCTAssertEqual(processor.dispatchedActions.last, .emailTypeChanged(.website))
    }

    /// Updating the username generator forwarded email service dispatches the
    /// `.usernameForwardedEmailServiceChanged` action.
    @MainActor
    func test_menuUsernameForwardedEmailServiceChanged() throws {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .forwardedEmail
        processor.state.usernameState.forwardedEmailService = .addyIO
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.service)
        try menuField.select(newValue: ForwardedEmailServiceType.fastmail)
        XCTAssertEqual(processor.dispatchedActions.last, .usernameForwardedEmailServiceChanged(.fastmail))
    }

    /// Tapping the password history button dispatches the `.showPasswordHistory` action.
    @MainActor
    func test_showPasswordHistory_tapped() throws {
        let button = try subject.inspect().find(button: Localizations.passwordHistory)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .showPasswordHistory)
    }

    /// Tapping the select button dispatches the `.selectButtonPressed` action.
    @MainActor
    func test_selectButton_tap() async throws {
        processor.state.presentationMode = .inPlace
        let button = try subject.inspect().find(button: Localizations.select)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .selectButtonPressed)
    }

    /// Updating the slider value dispatches the `.sliderValueChanged` action.
    @MainActor
    func test_sliderValueChanged() throws {
        let field = SliderField<GeneratorState>(
            keyPath: \.passwordState.lengthDouble,
            range: 5 ... 128,
            sliderAccessibilityId: "PasswordLengthSlider",
            sliderValueAccessibilityId: "PasswordLengthLabel",
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
    @MainActor
    func test_stepperValueChanged() throws {
        let field = StepperField<GeneratorState>(
            accessibilityId: "MinNumberValueLabel",
            keyPath: \.passwordState.minimumNumber,
            range: 0 ... 5,
            title: Localizations.minNumbers,
            value: 1
        )
        let stepper = try subject.inspect().find(
            BitwardenStepperType.self,
            containing: Localizations.minNumbers
        )
        try stepper.increment()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .stepperValueChanged(field: field, value: 2)
        )
    }

    /// Updating the text value dispatches the `.textValueChanged` action.
    @MainActor
    func test_textValueChanged() throws {
        processor.state.generatorType = .passphrase
        let field = FormTextField<GeneratorState>(
            accessibilityId: "WordSeparatorEntry",
            autocapitalization: .never,
            isAutocorrectDisabled: true,
            keyPath: \.passwordState.wordSeparator,
            title: Localizations.wordSeparator,
            value: "-"
        )
        let textField = try subject.inspect().find(textField: "")
        try textField.setInput("!!")
        XCTAssertEqual(processor.dispatchedActions.last, .textValueChanged(field: field, value: "!!"))
    }

    /// Updating the toggle value dispatches the `.toggleValueChanged()` action.
    @MainActor
    func test_toggleField_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let field = ToggleField<GeneratorState>(
            accessibilityId: "LowercaseAtoZToggle",
            accessibilityLabel: Localizations.lowercaseAtoZ,
            isDisabled: false,
            isOn: true,
            keyPath: \.passwordState.containsLowercase,
            title: "a-z"
        )
        let toggle = try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.lowercaseAtoZ)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleValueChanged(field: field, isOn: false))
    }

    // MARK: Snapshots

    /// Test a snapshot of the copied value toast.
    @MainActor
    func test_snapshot_generatorViewToast() {
        processor.state.generatedValue = "pa11w0rd"
        processor.state.showCopiedValueToast()
        assertSnapshot(
            of: snapshotView,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the passphrase generation view.
    @MainActor
    func test_snapshot_generatorViewPassphrase() {
        processor.state.generatorType = .passphrase
        assertSnapshots(
            of: snapshotView,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// Test a snapshot of the password generation view.
    @MainActor
    func test_snapshot_generatorViewPassword() {
        processor.state.generatorType = .password
        assertSnapshots(
            of: snapshotView,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// Test a snapshot of the password generation view with the select button.
    @MainActor
    func test_snapshot_generatorViewPassword_inPlace() {
        processor.state.generatorType = .password
        processor.state.presentationMode = .inPlace
        assertSnapshot(of: snapshotView, as: .tallPortrait)
    }

    /// Test a snapshot of the password generation view with a policy in effect.
    @MainActor
    func test_snapshot_generatorViewPassword_policyInEffect() {
        processor.state.isPolicyInEffect = true
        processor.state.policyOptions = PasswordGenerationOptions(type: .password, overridePasswordType: true)
        assertSnapshot(
            of: snapshotView,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the catch-all username generation view.
    @MainActor
    func test_snapshot_generatorViewUsernameCatchAll() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .catchAllEmail
        assertSnapshots(
            of: snapshotView,
            as: [
                Snapshotting.portrait(drawHierarchyInKeyWindow: true),
                Snapshotting.portraitDark(drawHierarchyInKeyWindow: true),
                Snapshotting.tallPortraitAX5(heightMultiple: 1.5, drawHierarchyInKeyWindow: true),
            ]
        )
    }

    /// Test a snapshot of the forwarded email alias generation view.
    @MainActor
    func test_snapshot_generatorViewUsernameForwarded() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .forwardedEmail
        assertSnapshot(
            of: snapshotView,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the plus addressed username generation view.
    @MainActor
    func test_snapshot_generatorViewUsernamePlusAddressed() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .plusAddressedEmail
        assertSnapshot(
            of: snapshotView,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the plus addressed username generation view with the select button.
    @MainActor
    func test_snapshot_generatorViewUsernamePlusAddressed_inPlace() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .plusAddressedEmail
        processor.state.presentationMode = .inPlace
        assertSnapshot(of: snapshotView, as: .defaultPortrait)
    }

    /// Test a snapshot of the random word username generation view.
    @MainActor
    func test_snapshot_generatorViewUsernameRandomWord() {
        processor.state.generatorType = .username
        processor.state.usernameState.usernameGeneratorType = .randomWord
        assertSnapshot(
            of: snapshotView,
            as: .defaultPortrait
        )
    }

    /// Tests the snapshot with the learn generator action card.
    @MainActor
    func test_snapshot_generatorView_learnGeneratorActionCard() throws {
        processor.state.isLearnGeneratorActionCardEligible = true
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark]
        )
    }
}
