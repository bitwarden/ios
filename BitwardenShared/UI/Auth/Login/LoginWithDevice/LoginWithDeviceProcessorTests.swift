import XCTest

@testable import BitwardenShared

class LoginWithDeviceProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authService: MockAuthService!
    var coordinator: MockCoordinator<AuthRoute>!
    var errorReporter: MockErrorReporter!
    var subject: LoginWithDeviceProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authService = MockAuthService()
        coordinator = MockCoordinator<AuthRoute>()
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

    /// `perform(_:)` with `.appeared` sets the fingerprint phrase in the state.
    func test_perform_appeared() async {
        authService.initiateLoginWithDeviceResult = .success("fingerprint")

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.fingerprintPhrase, "fingerprint")
    }

    /// `perform(_:)` with `.appeared` handles any errors.
    func test_perform_appeared_error() async {
        authService.initiateLoginWithDeviceResult = .failure(BitwardenTestError.example)

        await subject.perform(.appeared)

        XCTAssertEqual(coordinator.alertShown.last, Alert.defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.resendNotification` updates the fingerprint phrase in the state.
    func test_perform_resendNotification() async {
        authService.initiateLoginWithDeviceResult = .success("fingerprint2")

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.fingerprintPhrase, "fingerprint2")
    }

    /// `receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
