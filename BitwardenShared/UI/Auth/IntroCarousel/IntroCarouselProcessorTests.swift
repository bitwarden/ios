import BitwardenKitMocks
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

    /// `perform(_:)` with `.createAccount` navigates to the start registration view.
    @MainActor
    func test_perform_createAccount() async {
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
}
