import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - EmailAccessProcessorTests

class EmailAccessProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<TwoFactorNoticeRoute, Void>!
    var subject: EmailAccessProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        let services = ServiceContainer.withMocks()

        subject = EmailAccessProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: EmailAccessState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `.perform` with `.continueTapped` navigates to set up two factor
    /// when the user does not indicate they can access their email
    @MainActor
    func test_perform_continueTapped_canAccessEmail_false() async {
        subject.state.canAccessEmail = false
        await subject.perform(.continueTapped)
        XCTAssertEqual(coordinator.routes.last, .setUpTwoFactor)
    }

    /// `.perform` with `.continueTapped` updates the state and navigates to dismiss
    /// when the user indicates they can access their email
    @MainActor
    func test_perform_continueTapped_canAccessEmail_true() {

    }

    /// `.receive()` with `.canAccessEmailChanged` updates the state
    @MainActor
    func test_receive_canAccessEmailChanged() {
        subject.receive(.canAccessEmailChanged(true))
        XCTAssertTrue(subject.state.canAccessEmail)
        subject.receive(.canAccessEmailChanged(false))
        XCTAssertFalse(subject.state.canAccessEmail)
    }
}
