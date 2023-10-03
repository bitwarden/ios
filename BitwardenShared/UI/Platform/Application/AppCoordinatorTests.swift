import XCTest

@testable import BitwardenShared

// MARK: - AppCoordinatorTests

@MainActor
class AppCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var module: MockAppModule!
    var navigator: MockRootNavigator!
    var subject: AppCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        module = MockAppModule()
        navigator = MockRootNavigator()
        subject = AppCoordinator(
            module: module,
            navigator: navigator
        )
    }

    override func tearDown() {
        super.tearDown()
        module = nil
        navigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `didCompleteAuth()` starts the tab coordinator and navigates to the proper tab route.
    func test_didCompleteAuth() {
        subject.didCompleteAuth()
        XCTAssertTrue(module.tabCoordinator.isStarted)
        XCTAssertEqual(module.tabCoordinator.routes, [.vault])
    }

    /// `navigate(to:)` with `.onboarding` starts the auth coordinator and navigates to the proper auth route.
    func test_navigateTo_auth() throws {
        subject.navigate(to: .auth(.landing))

        XCTAssertTrue(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }

    /// `navigate(to:)` with `.auth(.landing)` twice uses the existing coordinator, rather than creating a new one.
    func test_navigateTo_authTwice() {
        subject.navigate(to: .auth(.landing))
        subject.navigate(to: .auth(.landing))

        XCTAssertEqual(module.authCoordinator.routes, [.landing, .landing])
    }

    /// `navigate(to:)` with `.tab(.vault)` starts the tab coordinator and navigates to the proper tab route.
    func test_navigateTo_tab() {
        subject.navigate(to: .tab(.vault))
        XCTAssertTrue(module.tabCoordinator.isStarted)
        XCTAssertEqual(module.tabCoordinator.routes, [.vault])
    }

    /// `navigate(to:)` with `.tab(.vault)` twice uses the existing coordinator, rather than creating a new one.
    func test_navigateTo_tabTwice() {
        subject.navigate(to: .tab(.vault))
        subject.navigate(to: .tab(.vault))

        XCTAssertEqual(module.tabCoordinator.routes, [.vault, .vault])
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    func test_show_hide_loadingOverlay() throws {
        navigator.rootViewController = UIViewController()
        try setKeyWindowRoot(viewController: XCTUnwrap(subject.navigator.rootViewController))

        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.showLoadingOverlay(LoadingOverlayState(title: "Loading..."))
        XCTAssertNotNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.hideLoadingOverlay()
        waitFor { window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag) == nil }
        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
    }

    /// `start()` doesn't navigate anywhere (first route is managed by AppProcessor).
    func test_start() {
        subject.start()

        XCTAssertFalse(module.authCoordinator.isStarted)
    }
}
