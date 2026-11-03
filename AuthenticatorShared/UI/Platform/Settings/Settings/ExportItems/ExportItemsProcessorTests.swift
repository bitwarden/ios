import BitwardenKitMocks
import BitwardenResources
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
    func test_receive_exportItemsTapped_unencrypted_error() async throws {
        exportService.exportFileContentResult = .failure(BitwardenTestError.example)
        subject.state.fileFormat = .csv
        subject.receive(.exportItemsTapped)

        // Select the alert action to export.
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.export)
        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
    }

    /// `.receive()` with  `.exportItemsTapped` passes a file url to the coordinator on success.
    @MainActor
    func test_receive_exportItemsTapped_unencrypted_success() async throws {
        let testURL = URL(string: "www.bitwarden.com")!
        exportService.exportFileContentResult = .success("")
        exportService.writeToFileResult = .success(testURL)
        subject.state.fileFormat = .json
        subject.receive(.exportItemsTapped)

        // Select the alert action to export.
        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.export)
        XCTAssertEqual(coordinator.routes.last, .shareExportedItems(testURL))
    }

    /// `.receive()` with `.fileFormatTypeChanged()` updates the file format.
    @MainActor
    func test_receive_fileFormatTypeChanged() {
        subject.receive(.fileFormatTypeChanged(.csv))

        XCTAssertEqual(subject.state.fileFormat, .csv)
    }
}
