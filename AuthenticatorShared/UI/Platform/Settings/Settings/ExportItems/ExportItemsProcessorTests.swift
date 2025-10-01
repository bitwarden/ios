import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import AuthenticatorShared

class ExportItemsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var exportService: MockExportItemsService!
    var subject: ExportItemsProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        errorReporter = MockErrorReporter()
        exportService = MockExportItemsService()
        let services = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            exportItemsService: exportService,
        )

        subject = ExportItemsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        exportService = nil
        subject = nil
    }

    // MARK: Tests

    /// `loadData` loads the initial data for the view.
    func test_perform_loadData() async {
        await subject.perform(.loadData)
    }

    /// `.receive()` with `.dismiss` dismisses the view and clears any files.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertTrue(exportService.didClearFiles)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.receive()` with `.exportItemsTapped` shows the confirm alert for unencrypted formats.
    @MainActor
    func test_receive_exportItemsTapped_unencrypted() {
        subject.state.fileFormat = .json
        subject.receive(.exportItemsTapped)

        // Confirm that the correct alert is displayed.
        XCTAssertEqual(coordinator.alertShown.last, .confirmExportItems(action: {}))
    }

    /// `.receive()` with  `.exportItemsTapped` logs an error on export failure.
    @MainActor
    func test_receive_exportItemsTapped_unencrypted_error() throws {
        exportService.exportFileContentResult = .failure(BitwardenTestError.example)
        subject.state.fileFormat = .csv
        subject.receive(.exportItemsTapped)

        // Select the alert action to export.
        let exportAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        let task = Task {
            await exportAction.handler?(exportAction, [])
        }
        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()
        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
    }

    /// `.receive()` with  `.exportItemsTapped` passes a file url to the coordinator on success.
    @MainActor
    func test_receive_exportItemsTapped_unencrypted_success() throws {
        let testURL = URL(string: "www.bitwarden.com")!
        exportService.exportFileContentResult = .success("")
        exportService.writeToFileResult = .success(testURL)
        subject.state.fileFormat = .json
        subject.receive(.exportItemsTapped)

        // Select the alert action to export.
        let exportAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        let task = Task {
            await exportAction.handler?(exportAction, [])
        }
        waitFor(!coordinator.routes.isEmpty)
        task.cancel()
        XCTAssertEqual(coordinator.routes.last, .shareExportedItems(testURL))
    }

    /// `.receive()` with `.fileFormatTypeChanged()` updates the file format.
    @MainActor
    func test_receive_fileFormatTypeChanged() {
        subject.receive(.fileFormatTypeChanged(.csv))

        XCTAssertEqual(subject.state.fileFormat, .csv)
    }
}
