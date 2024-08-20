import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - CreateAccountViewTests

class CreateAccountViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<CreateAccountState, CreateAccountAction, CreateAccountEffect>!
    var subject: CreateAccountView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: CreateAccountState())
        let store = Store(processor: processor)
        subject = CreateAccountView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the check for security breaches toggle dispatches the `.toggleCheckDataBreaches()` action.
    @MainActor
    func test_checkBreachesToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let toggle = try subject.inspect().find(viewWithId: ViewIdentifier.CreateAccount.checkBreaches).toggle()
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleCheckDataBreaches(true))
    }

    /// Updating the text field dispatches the `.emailTextChanged()` action.
    @MainActor
    func test_emailField_updateValue() throws {
        let textfield = try subject.inspect().find(viewWithId: Localizations.emailAddress).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .emailTextChanged("text"))
    }

    /// Updating the text field dispatches the `.passwordHintTextChanged()` action.
    @MainActor
    func test_hintField_updateValue() throws {
        let textfield = try subject.inspect().find(viewWithId: Localizations.masterPasswordHint).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .passwordHintTextChanged("text"))
    }

    /// Updating the text field dispatches the `.passwordTextChanged()` action.
    @MainActor
    func test_masterPasswordField_updateValue() throws {
        processor.state.arePasswordsVisible = true
        let textfield = try subject.inspect().find(viewWithId: Localizations.masterPassword).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .passwordTextChanged("text"))
    }

    /// Tapping the password visibility icon changes whether or not passwords are visible.
    @MainActor
    func test_passwordVisibility_tap() throws {
        processor.state.arePasswordsVisible = false
        let visibilityIcon = try subject.inspect().find(
            viewWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow
        ).button()
        try visibilityIcon.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .togglePasswordVisibility(true))
    }

    /// Updating the text field dispatches the `.retypePasswordTextChanged()` action.
    @MainActor
    func test_retypePasswordField_updateValue() throws {
        processor.state.arePasswordsVisible = true
        let textfield = try subject.inspect().find(viewWithId: Localizations.retypeMasterPassword).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .retypePasswordTextChanged("text"))
    }

    /// Tapping the submit button performs the `.createAccount` effect.
    @MainActor
    func test_submitButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.submit)
        try button.tap()

        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .createAccount)
    }

    /// Tapping the terms and privacy policy toggle dispatches the `.toggleTermsAndPrivacy()` action.
    @MainActor
    func test_termsAndPrivacyToggle_tap() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let toggle = try subject.inspect().find(viewWithId: ViewIdentifier.CreateAccount.termsAndPrivacy).toggle()
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleTermsAndPrivacy(true))
    }

    // MARK: Snapshots

    /// Tests the view renders correctly when the text fields are all empty.
    @MainActor
    func test_snapshot_empty() {
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Tests the view renders correctly when text fields are hidden.
    @MainActor
    func test_snapshot_textFields_hidden() throws {
        processor.state.arePasswordsVisible = false
        processor.state.emailText = "email@example.com"
        processor.state.passwordText = "12345"
        processor.state.retypePasswordText = "12345"
        processor.state.passwordHintText = "wink wink"
        processor.state.passwordStrengthScore = 0

        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Tests the view renders correctly when the text fields are all populated.
    @MainActor
    func test_snapshot_textFields_populated() throws {
        processor.state.arePasswordsVisible = true
        processor.state.emailText = "email@example.com"
        processor.state.passwordText = "12345"
        processor.state.retypePasswordText = "12345"
        processor.state.passwordHintText = "wink wink"
        processor.state.passwordStrengthScore = 0

        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Tests the view renders correctly when the toggles are on.
    @MainActor
    func test_snapshot_toggles_on() throws {
        processor.state.isTermsAndPrivacyToggleOn = true
        processor.state.isCheckDataBreachesToggleOn = true

        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Tests the view renders correctly when the feature flag for native create account is on.
    @MainActor
    func test_nativeCreateAccountFlow() throws {
        processor.state.nativeCreateAccountFeatureFlag = true
        assertSnapshots(
            of: subject,
            as: [
                .tallPortrait,
                .portraitDark(heightMultiple: 2),
                .tallPortraitAX5(),
            ]
        )
    }

    /// Tapping the continue button performs the `.createAccount` effect.
    @MainActor
    func test_continueButton_tap_withValidFields() throws {
        processor.state.nativeCreateAccountFeatureFlag = true
        processor.state.passwordText = "123456789101112"
        processor.state.retypePasswordText = "123456789101112"

        let button = try subject.inspect().find(button: Localizations.continue)
        try button.tap()

        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .createAccount)
    }

    /// Continue button is disabled when password requirements are not met.
    @MainActor
    func test_continueButton_disabled() throws {
        processor.state.nativeCreateAccountFeatureFlag = true

        let button = try subject.inspect().find(button: Localizations.continue)
        XCTAssertTrue(button.isDisabled())
    }

    /// Tapping the learn more button will dispatch the correct action.
    @MainActor
    func test_learnMoreButton_tap() throws {
        processor.state.nativeCreateAccountFeatureFlag = true

        let button = try subject.inspect().find(button: Localizations.learnMore)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .learnMoreTapped)
    }

    /// Tapping the prevent account lock button will dispatch the correct action.
    @MainActor
    func test_preventAccountLocked_tap() throws {
        processor.state.nativeCreateAccountFeatureFlag = true

        let button = try subject.inspect().find(button: Localizations.learnAboutWaysToPreventAccountLockout)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .preventAccountLockTapped)
    }
}
