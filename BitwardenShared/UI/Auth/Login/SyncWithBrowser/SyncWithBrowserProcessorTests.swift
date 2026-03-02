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

    /// `perform(_:)` with `.launchBrowserTapped` sets the URL to open and dismisses the view.
    @MainActor
    func test_perform_launchBrowserTapped_setsUrlAndDismisses() async {
        await subject.perform(.launchBrowserTapped)

        XCTAssertEqual(subject.state.url, environmentService.proxyCookieRedirectConnectorURL)
        XCTAssertTrue(delegate.dismissCalled)
        XCTAssertNil(delegate.dismissAction)
    }

    // MARK: Tests - ClearURL Action

    /// `receive(_:)` with `.clearURL` clears the URL from state.
    @MainActor
    func test_receive_clearURL_clearsStateUrl() {
        subject.state.url = URL(string: "https://example.com")

        subject.receive(.clearURL)

        XCTAssertNil(subject.state.url)
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

        try await waitForAsync { self.serverCommunicationConfigAPIService.cookiesAcquiredResult != nil }

        let result = try XCTUnwrap(serverCommunicationConfigAPIService.cookiesAcquiredResult)
        let cookies = try result.get()
        XCTAssertNil(cookies)
    }
}

// MARK: - MockSyncWithBrowserProcessorDelegate

class MockSyncWithBrowserProcessorDelegate: SyncWithBrowserProcessorDelegate {
    var dismissCalled = false
    var dismissAction: DismissAction?

    func dismiss(action: DismissAction?) {
        dismissCalled = true
        dismissAction = action
    }
}
