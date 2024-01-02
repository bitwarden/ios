import SnapshotTesting
import XCTest

@testable import BitwardenShared

class ExportVaultViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ExportVaultState, ExportVaultAction, Void>!
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

    /// Updating the text field in the password field sends the `.passwordTextChanged()` action.
    func test_passwordField_updateValue() throws {
        processor.state.isPasswordVisible = true
        let textfield = try subject.inspect().find(viewWithId: Localizations.masterPassword).textField()
        try textfield.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .passwordTextChanged("text"))
    }

    /// Tapping the password visibility icon changes whether or not the password is visible.
    func test_passwordVisibility_tap() throws {
        processor.state.isPasswordVisible = false
        let visibilityIcon = try subject.inspect().find(
            viewWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow
        ).button()
        try visibilityIcon.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .togglePasswordVisibility(true))
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    func test_snapshot_empty() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The populated view renders correctly.
    func test_snapshot_populated() {
        processor.state.passwordText = "password"
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
