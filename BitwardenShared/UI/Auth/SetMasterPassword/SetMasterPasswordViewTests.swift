import BitwardenResources
import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class SetMasterPasswordViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SetMasterPasswordState, SetMasterPasswordAction, SetMasterPasswordEffect>!
    var subject: SetMasterPasswordView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SetMasterPasswordState(organizationIdentifier: "ORG_ID"))
        subject = SetMasterPasswordView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping on the cancel button dispatches the `.cancelPressed` action.
    @MainActor
    func test_cancel_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        waitFor(!processor.effects.isEmpty)
        XCTAssertEqual(processor.effects.last, .cancelPressed)
    }

    /// Cancel button should be hidden for tde privilege elevation.
    @MainActor
    func test_cancel_hidden() throws {
        processor.state.isPrivilegeElevation = true
        XCTAssertThrowsError(try subject.inspect().find(button: Localizations.cancel))
    }

    /// Tapping the current master password visibility icon changes whether the master passwords are visible.
    @MainActor
    func test_masterPasswordVisibility_tap() throws {
        processor.state.isMasterPasswordRevealed = false
        let visibilityIcon = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "NewPasswordVisibilityToggle"
        ).button()
        try visibilityIcon.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .revealMasterPasswordFieldPressed(true))
    }

    /// Editing the text in the master password text field dispatches the `.masterPasswordChanged` action.
    @MainActor
    func test_masterPassword_change() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.masterPasswordRequired)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }

    /// Editing the text in the master password hint text field dispatches the `.masterPasswordHintChanged` action.
    @MainActor
    func test_masterPasswordHint_change() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.masterPasswordHint)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordHintChanged("text"))
    }

    /// Editing the text in the re-type master password text field dispatches the `.masterPasswordRetypeChanged` action.
    @MainActor
    func test_masterPasswordRetype_change() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.retypeMasterPasswordRequired)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordRetypeChanged("text"))
    }

    /// Tapping the retype password visibility toggle changes whether the password retype is visible.
    @MainActor
    func test_masterPasswordRetypeVisibility_tap() throws {
        processor.state.isMasterPasswordRevealed = false
        let visibilityIcon = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "RetypePasswordVisibilityToggle"
        ).button()
        try visibilityIcon.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .revealMasterPasswordFieldPressed(true))
    }

    /// Tapping on the save button performs the `.saveTapped` effect.
    @MainActor
    func test_saveButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.save)
        try button.tap()
        waitFor(!processor.effects.isEmpty)
        XCTAssertEqual(processor.effects.last, .saveTapped)
    }

    // MARK: Snapshots

    /// A snapshot of the view with all filled values fields.
    @MainActor
    func test_snapshot_setPassword_filled() {
        processor.state.masterPassword = "password123"
        processor.state.masterPasswordRetype = "password123"
        processor.state.masterPasswordHint = "hint hint"
        processor.state.resetPasswordAutoEnroll = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                "portrait": .portrait(),
                "portraitDark": .portraitDark(),
                "tallPortraitAX5": .tallPortraitAX5(),
            ]
        )
    }

    /// A snapshot of the view for privilege elevation.
    @MainActor
    func test_snapshot_setPassword_privilege_elevation() {
        processor.state.isPrivilegeElevation = true
        processor.state.masterPassword = "password123"
        processor.state.masterPasswordRetype = "password123"
        processor.state.masterPasswordHint = "hint hint"
        processor.state.resetPasswordAutoEnroll = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                "portrait": .portrait(),
                "portraitDark": .portraitDark(),
                "tallPortraitAX5": .tallPortraitAX5(),
            ]
        )
    }
}
