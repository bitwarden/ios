import BitwardenResources
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - CompleteRegistrationViewTests

class CompleteRegistrationViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<CompleteRegistrationState, CompleteRegistrationAction, CompleteRegistrationEffect>!
    var subject: CompleteRegistrationView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: CompleteRegistrationState(
            emailVerificationToken: "emailVerificationToken",
            userEmail: "email@example.com"
        ))
        let store = Store(processor: processor)
        subject = CompleteRegistrationView(store: store)
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
        let toggle = try subject.inspect().find(viewWithId: ViewIdentifier.CompleteRegistration.checkBreaches).toggle()
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleCheckDataBreaches(true))
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
        let textfield = try subject.inspect().find(viewWithId: Localizations.masterPasswordRequired).textField()
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
        let textfield = try subject.inspect().find(viewWithId: Localizations.retypeMasterPasswordRequired).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .retypePasswordTextChanged("text"))
    }

    /// Tapping the submit button performs the `.CompleteRegistration` effect.
    @MainActor
    func test_createAccountButton_tap() throws {
        processor.state.passwordText = "123456789101112"
        processor.state.retypePasswordText = "123456789101112"
        let button = try subject.inspect().find(button: Localizations.continue)
        try button.tap()

        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .completeRegistration)
    }

    /// Continue button is disabled when password requirements are not met.
    @MainActor
    func test_continueButton_disabled() throws {
        let button = try subject.inspect().find(button: Localizations.continue)
        XCTAssertTrue(button.isDisabled())
    }

    /// Tapping the learn more button will dispatch the correct action.
    @MainActor
    func test_learnMoreButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.learnMore)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .learnMoreTapped)
    }

    /// Tapping the prevent account lock button will dispatch the correct action.
    @MainActor
    func test_preventAccountLocked_tap() throws {
        let button = try subject.inspect().find(button: Localizations.learnAboutWaysToPreventAccountLockout)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .preventAccountLockTapped)
    }

    // MARK: Snapshots

    /// Tests the view renders correctly.
    @MainActor
    func test_snapshot_empty_nativeCreateAccountFlow() throws {
        assertSnapshots(
            of: subject,
            as: [
                .tallPortrait,
                .portraitDark(heightMultiple: 2),
                .tallPortraitAX5(),
            ]
        )
    }

    /// Tests the view renders correctly when text fields are hidden.
    @MainActor
    func test_snapshot_textFields_hidden_nativeCreateAccountFlow() throws {
        processor.state.arePasswordsVisible = false
        processor.state.userEmail = "email@example.com"
        processor.state.passwordText = "12345"
        processor.state.retypePasswordText = "12345"
        processor.state.passwordHintText = "wink wink"
        processor.state.passwordStrengthScore = 0

        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Tests the view renders correctly when the text fields are all populated.
    @MainActor
    func test_snapshot_textFields_populated_nativeCreateAccountFlow() throws {
        processor.state.arePasswordsVisible = true
        processor.state.userEmail = "email@example.com"
        processor.state.passwordText = "12345"
        processor.state.retypePasswordText = "12345"
        processor.state.passwordHintText = "wink wink"
        processor.state.passwordStrengthScore = 0

        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Tests the view renders correctly when the toggles are on.
    @MainActor
    func test_snapshot_toggles_on_nativeCreateAccountFlow() throws {
        processor.state.isCheckDataBreachesToggleOn = true

        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
