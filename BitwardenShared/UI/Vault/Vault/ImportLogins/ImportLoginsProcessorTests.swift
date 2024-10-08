import XCTest

@testable import BitwardenShared

class ImportLoginsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: ImportLoginsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = ImportLoginsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                stateService: stateService
            ),
            state: ImportLoginsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.advanceNextPage` advances to the next page.
    @MainActor
    func test_receive_advanceNextPage() {
        XCTAssertEqual(subject.state.page, .intro)

        subject.receive(.advanceNextPage)
        XCTAssertEqual(subject.state.page, .step1)
    }

    /// `receive(_:)` with `.advancePreviousPage` advances to the previous page.
    @MainActor
    func test_receive_advancePreviousPage() {
        subject.state.page = .step1

        subject.receive(.advancePreviousPage)
        XCTAssertEqual(subject.state.page, .intro)

        // Advancing again stays at the first page.
        subject.receive(.advancePreviousPage)
        XCTAssertEqual(subject.state.page, .intro)
    }

    /// `perform(_:)` with `.importLoginsLater` shows an alert for confirming the user wants to
    /// import logins later.
    @MainActor
    func test_perform_importLoginsLater() async throws {
        stateService.activeAccount = .fixture()
        stateService.accountSetupImportLogins["1"] = .incomplete

        await subject.perform(.importLoginsLater)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .importLoginsLater {})
        try await alert.tapAction(title: Localizations.confirm)

        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertEqual(stateService.accountSetupImportLogins["1"], .setUpLater)
    }

    /// `perform(_:)` with `.importLoginsLater` logs an error if one occurs.
    @MainActor
    func test_perform_importLoginsLater_error() async throws {
        await subject.perform(.importLoginsLater)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .importLoginsLater {})
        try await alert.tapAction(title: Localizations.confirm)

        XCTAssertEqual(coordinator.routes, [.dismiss])
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.getStarted` shows an alert for the user to confirm they have a
    /// computer available.
    @MainActor
    func test_receive_getStarted() async throws {
        subject.receive(.getStarted)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .importLoginsComputerAvailable {})

        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.page, .step1)
    }
}
