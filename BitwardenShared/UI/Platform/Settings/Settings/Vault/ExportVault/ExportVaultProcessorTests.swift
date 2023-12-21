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

    /// Receiving `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// Receiving `.fileFormatTypeChanged()` updates the file format.
    func test_receive_fileFormatTypeChanged() {
        subject.receive(.fileFormatTypeChanged(.csv))

        XCTAssertEqual(subject.state.fileFormat, .csv)
    }

    /// Receiving `.passwordTextChanged()` updates the password text.
    func test_receive_passwordTextChanged() {
        subject.receive(.passwordTextChanged("password"))

        XCTAssertEqual(subject.state.passwordText, "password")
    }

    /// Receiving `.togglePasswordVisibility()` toggles the password visibility.
    func test_receive_togglePasswordVisibility() {
        subject.receive(.togglePasswordVisibility(true))
        XCTAssertTrue(subject.state.isPasswordVisible)

        subject.receive(.togglePasswordVisibility(false))
        XCTAssertFalse(subject.state.isPasswordVisible)
    }
}
