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
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var serverCommunicationConfigAPIService: MockServerCommunicationConfigAPIService!
    var subject: SyncWithBrowserProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        delegate = MockSyncWithBrowserProcessorDelegate()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        serverCommunicationConfigAPIService = MockServerCommunicationConfigAPIService()

        subject = SyncWithBrowserProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: ServiceContainer.withMocks(
                environmentService: environmentService,
                errorReporter: errorReporter,
                serverCommunicationConfigAPIService: serverCommunicationConfigAPIService,
            ),
            state: SyncWithBrowserState(),
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        delegate = nil
        environmentService = nil
        errorReporter = nil
        serverCommunicationConfigAPIService = nil
        subject = nil
    }

    // MARK: Tests - Appeared Effect

    /// `perform(_:)` with `.appeared` sets the environment URL from the environment service.
    @MainActor
    func test_perform_appeared_setsEnvironmentUrl() async {
        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.environmentUrl, environmentService.webVaultURL.absoluteString)
    }

    // MARK: Tests - LaunchBrowserTapped Effect

    /// `perform(_:)` with `.launchBrowserTapped` starts an ASWA session with the connector URL and,
    /// on success, dismisses with an action that delivers the acquired cookies.
    @MainActor
    func test_perform_launchBrowserTapped_success() async throws {
        let callbackURL = URL(string: "bitwarden://sso-cookie-vendor?cookie1=value1")!
        delegate.performWebAuthSessionResult = callbackURL

        await subject.perform(.launchBrowserTapped)

        XCTAssertEqual(delegate.performWebAuthSessionURL, environmentService.proxyCookieRedirectConnectorURL)
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

        XCTAssertEqual(delegate.performWebAuthSessionURL, environmentService.proxyCookieRedirectConnectorURL)
        XCTAssertTrue(delegate.dismissCalled)
        let dismissAction = try XCTUnwrap(delegate.dismissAction)

        dismissAction.action()

        try await waitForAsync { self.serverCommunicationConfigAPIService.cookiesAcquiredFromCalled }

        XCTAssertNil(serverCommunicationConfigAPIService.cookiesAcquiredFromURL)
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
