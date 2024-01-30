import XCTest

@testable import BitwardenShared

class LoginWithDeviceProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authService: MockAuthService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var subject: LoginWithDeviceProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authService = MockAuthService()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        errorReporter = MockErrorReporter()

        subject = LoginWithDeviceProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authService: authService,
                errorReporter: errorReporter
            ),
            state: LoginWithDeviceState()
        )
    }

    override func tearDown() {
        super.tearDown()

        authService = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// Perform with `.appeared` gets sets the fingerprint phrase in the state.
    func test_perform_appeared() async {
        authService.initiateLoginWithDeviceResult = .success("fingerprint")

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.fingerprintPhrase, "fingerprint")
    }

    /// If an error occurs when `.appeared` is performed, an alert is shown and an error is logged.
    func test_perform_appeared_error() async {
        authService.initiateLoginWithDeviceResult = .failure(BitwardenTestError.example)

        await subject.perform(.appeared)

        XCTAssertEqual(coordinator.alertShown.last, Alert.defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// Receiving `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
