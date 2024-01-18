import XCTest

@testable import BitwardenShared

class AttachmentsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultItemRoute>!
    var errorReporter: MockErrorReporter!
    var subject: AttachmentsProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()

        subject = AttachmentsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository
            ),
            state: AttachmentsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `fileSelectionCompleted()` updates the state with the new file values.
    func test_fileSelectionCompleted() {
        let data = Data("data".utf8)
        subject.fileSelectionCompleted(fileName: "exampleFile.txt", data: data)
        XCTAssertEqual(subject.state.fileName, "exampleFile.txt")
        XCTAssertEqual(subject.state.fileData, data)
    }

    /// `perform(_:)` with `.loadPremiumStatus` loads the premium status and displays an alert if necessary.
    func test_perform_loadPremiumStatus() async throws {
        vaultRepository.doesActiveAccountHavePremiumResult = .success(false)

        await subject.perform(.loadPremiumStatus)

        XCTAssertFalse(subject.state.hasPremium)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.premiumRequired))
    }

    /// `perform(_:)` with `.loadPremiumStatus` records any errors
    func test_perform_loadPremiumStatus_error() async throws {
        vaultRepository.doesActiveAccountHavePremiumResult = .failure(BitwardenTestError.example)

        await subject.perform(.loadPremiumStatus)

        XCTAssertFalse(subject.state.hasPremium)
        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.save` displays an error if the user doesn't have premium.
    func test_perform_save_noFile() async throws {
        subject.state.hasPremium = false

        await subject.perform(.save)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .inputValidationAlert(error: .init(message: Localizations.validationFieldRequired(Localizations.file)))
        )
    }

    /// `perform(_:)` with `.save` displays an error if the user doesn't have premium.
    func test_perform_save_noPremium() async throws {
        subject.state.fileName = "only cool people can see this file.txt"
        subject.state.hasPremium = false

        await subject.perform(.save)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.premiumRequired
            )
        )
    }

    /// `receive(_:)` with `.chooseFilePressed` navigates to the document browser.
    func test_receive_chooseFilePressed() async throws {
        subject.receive(.chooseFilePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.last)

        try await alert.tapAction(title: Localizations.browse)
        XCTAssertEqual(coordinator.routes.last, .fileSelection(.file))
        XCTAssertIdentical(coordinator.contexts.last as? FileSelectionDelegate, subject)

        try await alert.tapAction(title: Localizations.camera)
        XCTAssertEqual(coordinator.routes.last, .fileSelection(.camera))
        XCTAssertIdentical(coordinator.contexts.last as? FileSelectionDelegate, subject)

        try await alert.tapAction(title: Localizations.photos)
        XCTAssertEqual(coordinator.routes.last, .fileSelection(.photo))
        XCTAssertIdentical(coordinator.contexts.last as? FileSelectionDelegate, subject)
    }

    /// `receive(_:)` with `.dismissPressed` dismisses the view.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)

        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }
}
