import XCTest

@testable import BitwardenShared

class SelfHostedProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute>!
    var subject: SelfHostedProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        coordinator = MockCoordinator<AuthRoute>()
        subject = SelfHostedProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: SelfHostedState()
        )

        super.setUp()
    }

    override func tearDown() {
        coordinator = nil
        subject = nil

        super.tearDown()
    }

    // MARK: Tests

    /// Receiving `.apiUrlChanged` updates the state.
    func test_receive_apiUrlChanged() {
        subject.receive(.apiUrlChanged("api url"))

        XCTAssertEqual(subject.state.apiServerUrl, "api url")
    }

    /// Receiving `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// Receiving `.iconsUrlChanged` updates the state.
    func test_receive_iconsUrlChanged() {
        subject.receive(.iconsUrlChanged("icons url"))

        XCTAssertEqual(subject.state.iconsServerUrl, "icons url")
    }

    /// Receiving `.identityUrlChanged` updates the state.
    func test_receive_identityUrlChanged() {
        subject.receive(.identityUrlChanged("identity url"))

        XCTAssertEqual(subject.state.identityServerUrl, "identity url")
    }

    /// Receiving `.serverUrlChanged` updates the state.
    func test_receive_serverUrlChanged() {
        subject.receive(.serverUrlChanged("server url"))

        XCTAssertEqual(subject.state.serverUrl, "server url")
    }

    /// Receiving `.webVaultUrlChanged` updates the state.
    func test_receive_webVaultUrlChanged() {
        subject.receive(.webVaultUrlChanged("web vault url"))

        XCTAssertEqual(subject.state.webVaultServerUrl, "web vault url")
    }
}
