import BitwardenKitMocks
import BitwardenResources
import Foundation
import TestHelpers
import XCTest

@testable import AuthenticatorShared

class ImportItemsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var application: MockApplication!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var importItemsService: MockImportItemsService!
    var subject: ImportItemsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        application = MockApplication()
        errorReporter = MockErrorReporter()
        importItemsService = MockImportItemsService()
        coordinator = MockCoordinator()
        subject = ImportItemsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                application: application,
                errorReporter: errorReporter,
                importItemsService: importItemsService
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        application = nil
        coordinator = nil
        errorReporter = nil
        importItemsService = nil
        subject = nil
    }

    // MARK: Tests

    /// When the import process throws a `dataCorrupted` error, the processor shows an error alert.
    @MainActor
    func test_fileSelectionCompleted_corruptedFile() async throws {
        importItemsService.errorToThrow = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Not valid JSON")
        )
        let data = "Test Data".data(using: .utf8)!
        subject.fileSelectionCompleted(fileName: "Filename", data: data)

        try await waitForAsync { !self.coordinator.alertShown.isEmpty }
        XCTAssertEqual(
            coordinator.alertShown.last,
            .importFileCorrupted(action: {
                self.subject.state.url = ExternalLinksConstants.helpAndFeedback
            })
        )
        XCTAssertNil(subject.state.toast)
    }

    /// When the import process throws a `keyNotFound` error, the processor shows an error alert.
    @MainActor
    func test_fileSelectionCompleted_missingKey() async throws {
        importItemsService.errorToThrow = DecodingError.keyNotFound(
            AnyCodingKey(stringValue: "missingKey"),
            DecodingError.Context(
                codingPath: [
                    AnyCodingKey(stringValue: "services"),
                    AnyCodingKey(stringValue: "item 0"),
                ],
                debugDescription: "Missing key"
            )
        )
        let data = "Test Data".data(using: .utf8)!
        subject.fileSelectionCompleted(fileName: "Filename", data: data)

        try await waitForAsync { !self.coordinator.alertShown.isEmpty }
        XCTAssertEqual(
            coordinator.alertShown.last,
            .requiredInfoMissing(keyPath: "services.item 0.missingKey", action: {
                self.subject.state.url = ExternalLinksConstants.helpAndFeedback
            })
        )
        XCTAssertNil(subject.state.toast)
    }

    /// When the import process throws a `keyNotFound` error, the processor shows an error alert.
    @MainActor
    func test_fileSelectionCompleted_missingValue() async throws {
        importItemsService.errorToThrow = DecodingError.valueNotFound(
            String.self,
            DecodingError.Context(
                codingPath: [
                    AnyCodingKey(stringValue: "services"),
                    AnyCodingKey(stringValue: "item 0"),
                ],
                debugDescription: "Missing value"
            )
        )
        let data = "Test Data".data(using: .utf8)!
        subject.fileSelectionCompleted(fileName: "Filename", data: data)

        try await waitForAsync { !self.coordinator.alertShown.isEmpty }
        XCTAssertEqual(
            coordinator.alertShown.last,
            .requiredInfoMissing(keyPath: "services.item 0", action: {
                self.subject.state.url = ExternalLinksConstants.helpAndFeedback
            })
        )
        XCTAssertNil(subject.state.toast)
    }

    /// The processor hands the data returned from the file selector to the `ImportItemsService`. Upon
    /// successful import, it shows a Toast.
    @MainActor
    func test_fileSelectionCompleted_success() async throws {
        let data = "Test Data".data(using: .utf8)!
        subject.fileSelectionCompleted(fileName: "Filename", data: data)

        try await waitForAsync { self.subject.state.toast != nil }
        XCTAssertEqual(subject.state.toast?.text, Toast(text: Localizations.itemsImported).text)
        XCTAssertEqual(importItemsService.importItemsData, data)
    }

    /// When the import process throws a `TwoFasImporterError.passwordProtectedFile` error,
    /// the processor shows an error alert.
    @MainActor
    func test_fileSelectionCompleted_twoFasPasswordProtected() async throws {
        importItemsService.errorToThrow = TwoFasImporterError.passwordProtectedFile
        let data = "Test Data".data(using: .utf8)!
        subject.fileSelectionCompleted(fileName: "Filename", data: data)

        try await waitForAsync { !self.coordinator.alertShown.isEmpty }
        XCTAssertEqual(coordinator.alertShown.last, .twoFasPasswordProtected())
        XCTAssertNil(subject.state.toast)
    }

    /// When the import process throws a `keyNotFound` error, the processor shows an error alert.
    @MainActor
    func test_fileSelectionCompleted_typeMismatch() async throws {
        importItemsService.errorToThrow = DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: [
                    AnyCodingKey(stringValue: "services"),
                    AnyCodingKey(stringValue: "item 0"),
                ],
                debugDescription: "Type Mismatch"
            )
        )
        let data = "Test Data".data(using: .utf8)!
        subject.fileSelectionCompleted(fileName: "Filename", data: data)

        try await waitForAsync { !self.coordinator.alertShown.isEmpty }
        XCTAssertEqual(
            coordinator.alertShown.last,
            .typeMismatch(action: {
                self.subject.state.url = ExternalLinksConstants.helpAndFeedback
            })
        )
        XCTAssertNil(subject.state.toast)
    }

    /// When the import process throws an unexpected error, the processor logs the error..
    @MainActor
    func test_fileSelectionCompleted_unknownError() async throws {
        importItemsService.errorToThrow = BitwardenTestError.example
        let data = "Test Data".data(using: .utf8)!
        subject.fileSelectionCompleted(fileName: "Filename", data: data)

        try await waitForAsync { !self.errorReporter.errors.isEmpty }
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, BitwardenTestError.example)
        XCTAssertTrue(coordinator.alertShown.isEmpty)
        XCTAssertNil(subject.state.toast)
    }

    /// When the Processor receives a `.clearURL` action, it clears the url in the state.
    @MainActor
    func test_receive_clearURL() {
        subject.state.url = ExternalLinksConstants.helpAndFeedback
        subject.receive(.clearURL)
        XCTAssertNil(subject.state.url)
    }

    /// When the Processor receives a `.dismiss` action, it navigates to `.dismiss`.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// When the Processor receives a `.fileFormatTypeChanged(_)` action, it sets the file format type in the state.
    @MainActor
    func test_receive_fileFormatTypeChanged() {
        subject.receive(.fileFormatTypeChanged(.bitwardenJson))
        XCTAssertEqual(subject.state.fileFormat, .bitwardenJson)
    }

    /// When the Processor receives a `.importItemsTapped` action, it navigates to `.importItemsFileSelection`.
    @MainActor
    func test_receive_importItemsTapped_fileImport() {
        subject.state.fileFormat = .bitwardenJson
        subject.receive(.importItemsTapped)
        XCTAssertEqual(coordinator.routes.last, .importItemsFileSelection(route: .jsonFile))
    }

    /// When the Processor receives a `.importItemsTapped` action and a `nil` route, it sends the event
    @MainActor
    func test_receive_importItemsTapped_qrScan() async throws {
        subject.state.fileFormat = .googleQr
        subject.receive(.importItemsTapped)
        try await waitForAsync { !self.coordinator.events.isEmpty }
        XCTAssertEqual(coordinator.events.last, .importItemsQrCode)
    }

    /// When the Processor receives a `.toastShown(_)` action, it sets the toast in the state.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(text: "TOAST!")

        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)
    }
}

/// Testing struct to specify a CodingKey for certain error states.
struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
