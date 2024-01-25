import XCTest

@testable import BitwardenShared

class LoginWithDeviceProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<AuthRoute>!
    var subject: LoginWithDeviceProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator<AuthRoute>()

        subject = LoginWithDeviceProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(authRepository: authRepository),
            state: LoginWithDeviceState()
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// When `initiateLoginWithDevice(deviceId:email:)` fails, an alert is shown.
    func test_initiateLoginWithDevice_failure() async throws {
        authRepository.initiateLoginWithDeviceResult = .failure(BitwardenTestError.example)
        await subject.perform(.appeared)

        XCTAssertEqual(coordinator.routes.last, .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
    }

    /// Perform with `.appeared` gets sets the fingerprint phrase in the state.
    func test_perform_appeared() {
        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(subject.state.fingerprintPhrase == "fingerprint")
        task.cancel()

        XCTAssertEqual(subject.state.fingerprintPhrase, "fingerprint")
    }

    /// Receiving `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
