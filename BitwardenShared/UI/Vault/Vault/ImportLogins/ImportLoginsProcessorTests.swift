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

        subject.receive(.advanceNextPage)
        XCTAssertEqual(subject.state.page, .step2)

        subject.receive(.advanceNextPage)
        XCTAssertEqual(subject.state.page, .step3)

        // TODO: PM-11159 Sync vault
        subject.receive(.advanceNextPage)
        XCTAssertEqual(subject.state.page, .step3)
    }

    /// `receive(_:)` with `.advancePreviousPage` advances to the previous page.
    @MainActor
    func test_receive_advancePreviousPage() {
        subject.state.page = .step3

        subject.receive(.advancePreviousPage)
        XCTAssertEqual(subject.state.page, .step2)

        subject.receive(.advancePreviousPage)
        XCTAssertEqual(subject.state.page, .step1)

        subject.receive(.advancePreviousPage)
        XCTAssertEqual(subject.state.page, .intro)

        // Advancing again stays at the first page.
        subject.receive(.advancePreviousPage)
        XCTAssertEqual(subject.state.page, .intro)
    }

    /// `perform(_:)` with `.appeared` loads the user's web vault host.
    @MainActor
    func test_perform_appeared_webVaultHost() async throws {
        stateService.activeAccount = .fixture(settings: .fixture(
            environmentUrls: .fixture(webVault: URL(string: "https://example.com")!)
        ))

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.webVaultHost, "example.com")
    }

    /// `perform(_:)` with `.appeared` logs an error if one occurs.
    @MainActor
    func test_perform_appeared_webVaultHostError() async throws {
        await subject.perform(.appeared)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `perform(_:)` with `.appeared` defaults to the default web vault host if the user doesn't
    /// have a web vault URL.
    @MainActor
    func test_perform_appeared_webVaultHostNil() async throws {
        stateService.activeAccount = .fixture(settings: .fixture(
            environmentUrls: .fixture(base: nil, webVault: nil)
        ))

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.webVaultHost, Constants.defaultWebVaultHost)
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
