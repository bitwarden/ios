import XCTest

@testable import BitwardenShared

class ExportVaultProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var subject: ExportVaultProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        subject = ExportVaultProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `.receive()` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.receive()` with  `.exportVaultTapped` shows the confirm alert for encrypted formats.
    func test_receive_exportVaultTapped_encrypted() {
        subject.state.fileFormat = .jsonEncrypted
        subject.receive(.exportVaultTapped)

        // Confirm that the correct alert is displayed.
        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: true, action: {}))
    }

    /// `.receive()` with `.exportVaultTapped` shows the confirm alert for unencrypted formats.
    func test_receive_exportVaultTapped_unencrypted() {
        subject.state.fileFormat = .json
        subject.receive(.exportVaultTapped)

        // Confirm that the correct alert is displayed.
        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: false, action: {}))
    }

    /// `.receive()` with `.fileFormatTypeChanged()` updates the file format.
    func test_receive_fileFormatTypeChanged() {
        subject.receive(.fileFormatTypeChanged(.csv))

        XCTAssertEqual(subject.state.fileFormat, .csv)
    }

    /// `.receive()` with `.passwordTextChanged()` updates the password text.
    func test_receive_passwordTextChanged() {
        subject.receive(.passwordTextChanged("password"))

        XCTAssertEqual(subject.state.passwordText, "password")
    }

    /// `.receive()` with `.togglePasswordVisibility()` toggles the password visibility.
    func test_receive_togglePasswordVisibility() {
        subject.receive(.togglePasswordVisibility(true))
        XCTAssertTrue(subject.state.isPasswordVisible)

        subject.receive(.togglePasswordVisibility(false))
        XCTAssertFalse(subject.state.isPasswordVisible)
    }
}
