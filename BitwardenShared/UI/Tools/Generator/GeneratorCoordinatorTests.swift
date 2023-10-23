import XCTest

@testable import BitwardenShared

class GeneratorCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var stackNavigator: MockStackNavigator!
    var subject: GeneratorCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stackNavigator = MockStackNavigator()

        subject = GeneratorCoordinator(
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.generator` pushes the generator view onto the stack navigator.
    func test_navigateTo_generator() throws {
        subject.navigate(to: .generator)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is GeneratorView)
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    func test_show_hide_loadingOverlay() throws {
        stackNavigator.rootViewController = UIViewController()
        try setKeyWindowRoot(viewController: XCTUnwrap(stackNavigator.rootViewController))

        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.showLoadingOverlay(LoadingOverlayState(title: "Loading..."))
        XCTAssertNotNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.hideLoadingOverlay()
        waitFor { window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag) == nil }
        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
    }

    /// `start()` navigates to the generator view.
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.last?.view is GeneratorView)
    }
}
