import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

class ExportSettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var subject: ExportSettingsProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()

        subject = ExportSettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// Receiving `.exportToFileTapped` navigates to the export vault to file screen.
    @MainActor
    func test_receive_exportVaultToFileTapped() {
        subject.receive(.exportToFileTapped)

        XCTAssertEqual(coordinator.routes.last, .exportVaultToFile)
    }

    /// Receiving `.exportToAppTapped` navigates to the export vault to another app (Credential Exchange) screen.
    @MainActor
    func test_receive_exportVaultToAppTapped() {
        subject.receive(.exportToAppTapped)

        XCTAssertEqual(coordinator.routes.last, .exportVaultToApp)
    }
}
