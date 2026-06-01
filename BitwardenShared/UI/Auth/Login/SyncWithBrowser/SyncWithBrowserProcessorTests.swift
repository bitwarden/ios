import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class SyncWithBrowserProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<GlobalModalRoute, Void>!
    var delegate: MockSyncWithBrowserProcessorDelegate!
    var errorReporter: MockErrorReporter!
    var serverCommunicationConfigAPIService: MockServerCommunicationConfigAPIService!
    var subject: SyncWithBrowserProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        delegate = MockSyncWithBrowserProcessorDelegate()
        errorReporter = MockErrorReporter()
        serverCommunicationConfigAPIService = MockServerCommunicationConfigAPIService()

        subject = SyncWithBrowserProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                serverCommunicationConfigAPIService: serverCommunicationConfigAPIService,
            ),
            state: SyncWithBrowserState(vaultUrl: "https://example.com"),
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        delegate = nil
        errorReporter = nil
        serverCommunicationConfigAPIService = nil
        subject = nil
    }

    // MARK: Tests - LaunchBrowserTapped Effect

    /// `perform(_:)` with `.launchBrowserTapped` starts an ASWA session with the connector URL
    /// constructed from `state.vaultUrl` and, on success, dismisses with an action that delivers
    /// the acquired cookies.
    @MainActor
    func test_perform_launchBrowserTapped_success() async throws {
        let callbackURL = URL(string: "bitwarden://sso-cookie-vendor?cookie1=value1")!
        delegate.performWebAuthSessionResult = callbackURL

        await subject.perform(.launchBrowserTapped)

        XCTAssertEqual(
            delegate.performWebAuthSessionURL,
            URL(string: "https://example.com/proxy-cookie-redirect-connector.html"),
        )
        XCTAssertTrue(delegate.dismissCalled)
        let dismissAction = try XCTUnwrap(delegate.dismissAction)

        dismissAction.action()

        try await waitForAsync { self.serverCommunicationConfigAPIService.cookiesAcquiredFromCalled }

        XCTAssertEqual(serverCommunicationConfigAPIService.cookiesAcquiredFromURL, callbackURL)
    }

    /// `perform(_:)` with `.launchBrowserTapped` starts an ASWA session and, when the user cancels
    /// (nil callback URL), dismisses with an action that delivers nil cookies.
    @MainActor
    func test_perform_launchBrowserTapped_cancelled() async throws {
        delegate.performWebAuthSessionResult = nil

        await subject.perform(.launchBrowserTapped)

        XCTAssertEqual(
            delegate.performWebAuthSessionURL,
            URL(string: "https://example.com/proxy-cookie-redirect-connector.html"),
        )
        XCTAssertTrue(delegate.dismissCalled)
        let dismissAction = try XCTUnwrap(delegate.dismissAction)

        dismissAction.action()

        try await waitForAsync { self.serverCommunicationConfigAPIService.cookiesAcquiredFromCalled }

        XCTAssertNil(serverCommunicationConfigAPIService.cookiesAcquiredFromURL)
    }

    /// `perform(_:)` with `.launchBrowserTapped` logs an error and shows an alert when the vault URL
    /// cannot be parsed into a valid URL.
    @MainActor
    func test_perform_launchBrowserTapped_invalidVaultUrl() async {
        subject.state.vaultUrl = "example.com"

        await subject.perform(.launchBrowserTapped)

        XCTAssertNil(delegate.performWebAuthSessionURL)
        XCTAssertFalse(delegate.dismissCalled)
        XCTAssertEqual(errorReporter.errors.count, 1)
        XCTAssertEqual(errorReporter.errors as? [SyncWithBrowserProcessorError], [.invalidVaultURL])
        XCTAssertEqual(coordinator.errorAlertsShown.count, 1)
        XCTAssertEqual(coordinator.errorAlertsShown as? [SyncWithBrowserProcessorError], [.invalidVaultURL])
    }

    // MARK: Tests - ContinueWithoutSyncingTapped Action

    /// `receive(_:)` with `.continueWithoutSyncingTapped` calls the delegate with a dismiss action
    /// that signals cookie acquisition was cancelled.
    @MainActor
    func test_receive_continueWithoutSyncingTapped_callsDelegateWithAction() async throws {
        subject.receive(.continueWithoutSyncingTapped)

        XCTAssertTrue(delegate.dismissCalled)
        let dismissAction = try XCTUnwrap(delegate.dismissAction)

        dismissAction.action()

        try await waitForAsync { self.serverCommunicationConfigAPIService.cookiesAcquiredFromCalled }

        XCTAssertNil(serverCommunicationConfigAPIService.cookiesAcquiredFromURL)
    }
}

// MARK: - MockSyncWithBrowserProcessorDelegate

class MockSyncWithBrowserProcessorDelegate: SyncWithBrowserProcessorDelegate {
    var dismissCalled = false
    var dismissAction: DismissAction?
    var performWebAuthSessionURL: URL?
    var performWebAuthSessionResult: URL?

    func dismiss(action: DismissAction?) {
        dismissCalled = true
        dismissAction = action
    }

    func performWebAuthSession(url: URL) async -> URL? {
        performWebAuthSessionURL = url
        return performWebAuthSessionResult
    }
}
