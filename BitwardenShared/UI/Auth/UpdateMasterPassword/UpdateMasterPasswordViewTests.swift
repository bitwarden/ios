import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - UpdateMasterPasswordViewTests

class UpdateMasterPasswordViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<UpdateMasterPasswordState, UpdateMasterPasswordAction, UpdateMasterPasswordEffect>!
    var subject: UpdateMasterPasswordView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let state = UpdateMasterPasswordState(
            currentMasterPassword: "current master password",
            masterPassword: "new master password",
            masterPasswordHint: "new master password hint",
            masterPasswordPolicy: .init(
                minComplexity: 0,
                minLength: 20,
                requireUpper: true,
                requireLower: false,
                requireNumbers: false,
                requireSpecial: false,
                enforceOnLogin: true
            ),
            masterPasswordRetype: "new master password"
        )
        processor = MockProcessor(state: state)
        subject = UpdateMasterPasswordView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Editing the text in the current master password text field dispatches the `.currentMasterPasswordChanged`
    /// action.
    @MainActor
    func test_currentMasterPassword_change() throws {
        processor.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.currentMasterPassword)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .currentMasterPasswordChanged("text"))
    }

    /// Tapping the current master password visibility icon changes whether or not current master passwords are visible.
    @MainActor
    func test_currentMasterPasswordVisibility_tap() throws {
        processor.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        processor.state.isCurrentMasterPasswordRevealed = false
        let visibilityIcon = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "MasterPasswordVisibilityToggle"
        ).button()
        try visibilityIcon.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .revealCurrentMasterPasswordFieldPressed(true))
    }

    /// Tapping on the dismiss button dispatches the `.dismissPressed` action.
    @MainActor
    func test_logout_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.logOut)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .logoutPressed)
    }

    /// Editing the text in the master password text field dispatches the `.masterPasswordChanged` action.
    @MainActor
    func test_masterPassword_change() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.masterPassword)
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
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.retypeMasterPassword)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordRetypeChanged("text"))
    }

    /// Tapping the retype password visibility toggle changes whether the password retype is visible.
    @MainActor
    func test_masterPasswordRetypeVisibility_tap() throws {
        processor.state.isMasterPasswordRetypeRevealed = false
        let visibilityIcon = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "RetypePasswordVisibilityToggle"
        ).button()
        try visibilityIcon.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .revealMasterPasswordRetypeFieldPressed(true))
    }

    /// Tapping the new master password visibility icon changes whether or not new master passwords are visible.
    @MainActor
    func test_masterPasswordVisibility_tap() throws {
        processor.state.isMasterPasswordRetypeRevealed = false
        let visibilityIcon = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "NewPasswordVisibilityToggle"
        ).button()
        try visibilityIcon.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .revealMasterPasswordFieldPressed(true))
    }

    /// Tapping on the submit button performs the `.submitPressed` effect.
    @MainActor
    func test_submitButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.submit)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .submitPressed)
    }

    // MARK: Snapshots

    /// A snapshot of the view with all filled values fields.
    @MainActor
    func test_snapshot_resetPassword_withFilled_default() {
        processor.state.forcePasswordResetReason = .adminForcePasswordReset
        assertSnapshots(
            of: subject,
            as: [.portrait(heightMultiple: 1.25)]
        )
    }

    /// A snapshot of the view with all filled values fields in a dark mode.
    @MainActor
    func test_snapshot_resetPassword_withFilled_dark() {
        processor.state.forcePasswordResetReason = .adminForcePasswordReset
        assertSnapshots(
            of: subject,
            as: [.portrait(heightMultiple: 1.25)]
        )
    }

    /// A snapshot of the view with all filled values fields in a large text.
    @MainActor
    func test_snapshot_resetPassword_withFilled_large() {
        processor.state.forcePasswordResetReason = .adminForcePasswordReset
        assertSnapshots(
            of: subject,
            as: [.tallPortraitAX5(heightMultiple: 6)]
        )
    }

    /// A snapshot of the view with all filled values fields.
    @MainActor
    func test_snapshot_weakPassword_withFilled_default() {
        processor.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        assertSnapshots(
            of: subject,
            as: [.portrait(heightMultiple: 1.25)]
        )
    }

    /// A snapshot of the view with all filled values fields in a dark mode.
    @MainActor
    func test_snapshot_weakPassword_withFilled_dark() {
        processor.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        assertSnapshots(
            of: subject,
            as: [.portrait(heightMultiple: 1.25)]
        )
    }

    /// A snapshot of the view with all filled values fields in a large text.
    @MainActor
    func test_snapshot_weakPassword_withFilled_large() {
        processor.state.forcePasswordResetReason = .weakMasterPasswordOnLogin
        assertSnapshots(
            of: subject,
            as: [.tallPortraitAX5(heightMultiple: 6)]
        )
    }
}
