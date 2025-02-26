import XCTest

@testable import BitwardenShared

class IntroCarouselProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var subject: IntroCarouselProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator()

        subject = IntroCarouselProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                configService: configService
            ),
            state: IntroCarouselState()
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.createAccount` navigates to the create account view.
    @MainActor
    func test_perform_createAccount() async {
        await subject.perform(.createAccount)
        XCTAssertEqual(coordinator.routes.last, .createAccount)
    }

    /// `perform(_:)` with `.createAccount` navigates to the start registration view if email
    /// verification is enabled.
    @MainActor
    func test_perform_createAccount_emailVerificationEnabled() async {
        configService.featureFlagsBoolPreAuth[.emailVerification] = true
        await subject.perform(.createAccount)
        XCTAssertEqual(coordinator.routes.last, .startRegistration)
    }

    /// `receive(_:)` with `.currentPageIndexChanged` updates the current page index.
    @MainActor
    func test_receive_currentPageIndexChanged() {
        subject.receive(.currentPageIndexChanged(1))
        XCTAssertEqual(subject.state.currentPageIndex, 1)

        subject.receive(.currentPageIndexChanged(2))
        XCTAssertEqual(subject.state.currentPageIndex, 2)

        subject.receive(.currentPageIndexChanged(0))
        XCTAssertEqual(subject.state.currentPageIndex, 0)
    }

    /// `receive(_:)` with `.logIn` navigates to the landing view.
    @MainActor
    func test_receive_logIn() {
        subject.receive(.logIn)
        XCTAssertEqual(coordinator.routes.last, .landing)
    }

    /// `switchToLegacyCreateAccountFlow()` dismisses the currently presented view and navigates to
    /// create account.
    @MainActor
    func test_switchToLegacyCreateAccountFlow() throws {
        subject.switchToLegacyCreateAccountFlow()

        let dismissRoute = try XCTUnwrap(coordinator.routes.last)
        guard case let .dismissWithAction(action) = dismissRoute else {
            return XCTFail("Expected route `.dismissWithAction` not found.")
        }
        action?.action()

        XCTAssertEqual(coordinator.routes, [.dismissWithAction(action), .createAccount])
    }
}
