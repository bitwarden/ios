import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - AuthCoordinatorTests

class AuthCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var authDelegate: MockAuthDelegate!
    var rootNavigator: MockRootNavigator!
    var stackNavigator: MockStackNavigator!
    var subject: AuthCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authDelegate = MockAuthDelegate()
        rootNavigator = MockRootNavigator()
        stackNavigator = MockStackNavigator()
        subject = AuthCoordinator(
            delegate: authDelegate,
            rootNavigator: rootNavigator,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        authDelegate = nil
        rootNavigator = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.complete` notifies the delegate that auth has completed.
    func test_navigate_complete() {
        subject.navigate(to: .complete)
        XCTAssertTrue(authDelegate.didCompleteAuthCalled)
    }

    /// `navigate(to:)` with `.createAccount` pushes the create account view onto the stack navigator.
    func test_navigate_createAccount() {
        subject.navigate(to: .createAccount)

        // Placeholder assertion until the create account screen is added: BIT-157
        XCTAssertTrue(stackNavigator.actions.last?.view is CreateAccountView)
    }

    /// Tests that `navigate(to:)` with `.dismiss` dismisses the view.
    func test_navigate_dismiss() {
        subject.navigate(to: .createAccount)
        subject.navigate(to: .dismiss)

        XCTAssertEqual(stackNavigator.actions.last?.type, .dismissed)
    }

    /// `navigate(to:)` with `.enterpriseSingleSignOn` pushes the enterprise single sign-on view onto the stack
    /// navigator.
    func test_navigate_enterpriseSingleSignOn() {
        subject.navigate(to: .enterpriseSingleSignOn)
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `navigate(to:)` with `.landing` pushes the landing view onto the stack navigator.
    func test_navigate_landing() {
        subject.navigate(to: .landing)
        XCTAssertTrue(stackNavigator.actions.last?.view is LandingView)
    }

    /// `navigate(to:)` with `.landing` from `.login` pops back to the landing view.
    func test_navigate_landing_fromLogin() {
        stackNavigator.viewControllersToPop = [
            UIViewController(),
        ]
        subject.navigate(to: .landing)

        XCTAssertEqual(stackNavigator.actions.last?.type, .poppedToRoot)
    }

    /// `navigate(to:)` with `.login` pushes the login view onto the stack navigator.
    func test_navigate_login() throws {
        subject.navigate(to: .login(
            username: "username",
            region: .unitedStates,
            isLoginWithDeviceVisible: true
        ))

        XCTAssertEqual(stackNavigator.actions.last?.type, .pushed)
        let view = try XCTUnwrap(stackNavigator.actions.last?.view as? LoginView)
        let state = view.store.state
        XCTAssertEqual(state.username, "username")
        XCTAssertEqual(state.region, .unitedStates)
        XCTAssertTrue(state.isLoginWithDeviceVisible)
    }

    /// `navigate(to:)` with `.loginOptions` pushes the login options view onto the stack navigator.
    func test_navigate_loginOptions() {
        subject.navigate(to: .loginOptions)
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `navigate(to:)` with `.loginWithDevice` pushes the login with device view onto the stack navigator.
    func test_navigate_loginWithDevice() {
        subject.navigate(to: .loginWithDevice)
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `navigate(to:)` with `.masterPasswordHint` pushes the master password hint view onto the stack navigator.
    func test_navigate_masterPasswordHint() {
        subject.navigate(to: .masterPasswordHint)
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `navigate(to:)` with `.regionSelection` and no delegate has no effect.
    func test_navigate_regionSelection_withoutDelegate() throws {
        subject.navigate(to: .regionSelection)

        XCTAssertEqual(stackNavigator.alerts.count, 0)
    }

    /// `navigate(to:)` with `.regionSelection` and a delegate presents the region selection alert.
    func test_navigate_regionSelection_withDelegate() throws {
        let delegate = MockRegionSelectionDelegate()
        subject.navigate(to: .regionSelection, context: delegate)

        XCTAssertEqual(stackNavigator.alerts.count, 1)
        let alert = try XCTUnwrap(stackNavigator.alerts.last)
        XCTAssertEqual(alert.title, Localizations.loggingInOn)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 4)

        XCTAssertEqual(alert.alertActions[0].title, "bitwarden.com")
        alert.alertActions[0].handler?(alert.alertActions[0])
        XCTAssertEqual(delegate.regions.last, .unitedStates)

        XCTAssertEqual(alert.alertActions[1].title, "bitwarden.eu")
        alert.alertActions[1].handler?(alert.alertActions[1])
        XCTAssertEqual(delegate.regions.last, .europe)

        XCTAssertEqual(alert.alertActions[2].title, Localizations.selfHosted)
        alert.alertActions[2].handler?(alert.alertActions[2])
        XCTAssertEqual(delegate.regions.last, .selfHosted)
    }

    /// `rootNavigator` uses a weak reference and does not retain a value once the root navigator has been erased.
    func test_rootNavigator_resetWeakReference() {
        var rootNavigator: MockRootNavigator? = MockRootNavigator()
        subject = AuthCoordinator(
            delegate: authDelegate,
            rootNavigator: rootNavigator!,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
        XCTAssertNotNil(subject.rootNavigator)

        rootNavigator = nil
        XCTAssertNil(subject.rootNavigator)
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    func test_show_hide_loadingOverlay() throws {
        stackNavigator.rootViewController = UIViewController()
        try setKeyWindowRoot(viewController: XCTUnwrap(subject.stackNavigator.rootViewController))

        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.showLoadingOverlay(LoadingOverlayState(title: "Loading..."))
        XCTAssertNotNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.hideLoadingOverlay()
        waitFor { window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag) == nil }
        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
    }

    /// `start()` presents the stack navigator within the root navigator.
    func test_start() {
        subject.start()
        XCTAssertIdentical(rootNavigator.navigatorShown, stackNavigator)
    }
}

// MARK: - MockAuthDelegate

class MockAuthDelegate: AuthCoordinatorDelegate {
    var didCompleteAuthCalled = false

    func didCompleteAuth() {
        didCompleteAuthCalled = true
    }
}
