import XCTest

@testable import BitwardenShared

class DeleteAccountProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var coordinator: MockCoordinator<SettingsRoute>!
    var subject: DeleteAccountProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        coordinator = MockCoordinator<SettingsRoute>()
        subject = DeleteAccountProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                httpClient: client
            ),
            state: DeleteAccountState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// Receiving `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// Perform with `.deleteAccount` presents the master password prompt alert.
    func test_perform_deleteAccount() async {
        await subject.perform(.deleteAccount)

        XCTAssertEqual(try coordinator.unwrapLastRouteAsAlert(), .masterPasswordPrompt(completion: { _ in }))
    }
}
