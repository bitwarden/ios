import SnapshotTesting
import XCTest

@testable import BitwardenShared

class ExportVaultViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ExportVaultState, ExportVaultAction, ExportVaultEffect>!
    var subject: ExportVaultView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ExportVaultState())
        let store = Store(processor: processor)

        subject = ExportVaultView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismiss` action.
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Setting `disableIndividualVaultExport` disables the controls within the view.
    func test_disableIndividualVaultExport() throws {
        processor.state.disableIndividualVaultExport = true

        let button = try subject.inspect().find(button: Localizations.exportVault)
        XCTAssertTrue(button.isDisabled())

        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.fileFormat)
        XCTAssertTrue(menuField.isDisabled())

        let textfield = try subject.inspect().find(viewWithId: Localizations.masterPassword).textField()
        XCTAssertTrue(textfield.isDisabled())
    }

    /// Tapping the export vault button sends the `.exportVault` action.
    func test_exportVaultButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.exportVault)
        try button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .exportVaultTapped)
    }

    /// Updating the value of the file format sends the  `.fileFormatTypeChanged()` action.
    func test_fileFormatMenu_updateValue() throws {
        processor.state.fileFormat = .json
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.fileFormat)
        try menuField.select(newValue: ExportFormatType.csv)
        XCTAssertEqual(processor.dispatchedActions.last, .fileFormatTypeChanged(.csv))
    }

    /// Updating the text in the file password field sends the `.filePasswordTextChanged()` action.
    func test_filePasswordField_updateValue() throws {
        processor.state.fileFormat = .jsonEncrypted
        processor.state.isFilePasswordVisible = true
        let textfield = try subject.inspect().find(viewWithId: Localizations.filePassword).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .filePasswordTextChanged("text"))
    }

    /// Tapping the file password visibility icon changes whether or not the password is visible.
    func test_filePasswordVisibility_tap() throws {
        processor.state.fileFormat = .jsonEncrypted
        processor.state.isFilePasswordVisible = false
        let visibilityIcon = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "FilePasswordVisibilityToggle"
        ).button()
        try visibilityIcon.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleFilePasswordVisibility(true))
    }

    /// Updating the text in the file password confirmation field sends the
    /// `.filePasswordConfirmationTextChanged()` action.
    func test_filePasswordConfirmationField_updateValue() throws {
        processor.state.fileFormat = .jsonEncrypted
        processor.state.isFilePasswordVisible = true
        let textfield = try subject.inspect().find(viewWithId: Localizations.confirmFilePassword).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .filePasswordConfirmationTextChanged("text"))
    }

    /// Updating the text in the master password field sends the `.masterPasswordTextChanged()` action.
    func test_masterPasswordField_updateValue() throws {
        processor.state.isMasterPasswordOrOtpVisible = true
        let textfield = try subject.inspect().find(viewWithId: Localizations.masterPassword).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordOrOtpTextChanged("text"))
    }

    /// Tapping the master password visibility icon changes whether or not the password is visible.
    func test_masterPasswordVisibility_tap() throws {
        processor.state.isMasterPasswordOrOtpVisible = false
        let visibilityIcon = try subject.inspect().find(
            viewWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow
        ).button()
        try visibilityIcon.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleMasterPasswordOrOtpVisibility(true))
    }

    /// Tapping the send code button performs the `.sendCodeTapped` effect.
    func test_sendCode_tap() async throws {
        processor.state.hasMasterPassword = false
        let sendCodeButton = try subject.inspect().find(asyncButton: Localizations.sendCode)
        try await sendCodeButton.tap()
        XCTAssertEqual(processor.effects.last, .sendCodeTapped)
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    func test_snapshot_empty() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The populated view renders correctly.
    func test_snapshot_populated() {
        processor.state.masterPasswordOrOtpText = "password"
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The vault export disabled view renders correctly.
    func test_snapshot_vaultExportDisabled() {
        processor.state.disableIndividualVaultExport = true
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The JSON encrypted view renders correctly.
    func test_snapshot_jsonEncrypted() {
        processor.state.fileFormat = .jsonEncrypted
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The view for exporting the vault without a master password renders correctly.
    func test_snapshot_noMasterPassword() {
        processor.state.hasMasterPassword = false
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
