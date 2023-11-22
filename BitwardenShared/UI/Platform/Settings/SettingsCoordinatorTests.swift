import SwiftUI
import XCTest

@testable import BitwardenShared

class SettingsCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var delegate: MockSettingsCoordinatorDelegate!
    var stackNavigator: MockStackNavigator!
    var subject: SettingsCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        delegate = MockSettingsCoordinatorDelegate()
        stackNavigator = MockStackNavigator()

        subject = SettingsCoordinator(
            delegate: delegate,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        delegate = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.accountSecurity` pushes the account security view onto the stack navigator.
    func test_navigateTo_accountSecurity() throws {
        subject.navigate(to: .accountSecurity)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AccountSecurityView>)
    }

    /// `navigate(to:)` with `.alert` has the stack navigator present the alert.
    func test_navigateTo_alert() throws {
        let alert = Alert.defaultAlert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.genericErrorMessage
        )
        subject.navigate(to: .alert(alert))

        XCTAssertEqual(stackNavigator.alerts, [alert])
    }

    /// `navigate(to:)` with `.autoFill` pushes the auto-fill view onto the stack navigator.
    func test_navigateTo_autoFill() throws {
        subject.navigate(to: .autoFill)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AutoFillView>)
    }

    /// `navigate(to:)` with `.deleteAccount` presents the delete account view.
    func test_navigateTo_deleteAccount() throws {
        subject.navigate(to: .deleteAccount)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<DeleteAccountView>)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the presented view.
    func test_navigateTo_dismiss() throws {
        subject.navigate(to: .dismiss)

        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissed)
    }

    /// `navigate(to:)` with `.lockVault` navigates the user to the login view.
    func test_navigateTo_lockVault() throws {
        subject.navigate(to: .lockVault(account: .fixture()))

        XCTAssertTrue(delegate.didLockVaultCalled)
    }

    /// `navigate(to:)` with `.logout` informs the delegate that the user logged out.
    func test_navigateTo_logout() throws {
        subject.navigate(to: .logout)

        XCTAssertTrue(delegate.didLogoutCalled)
    }

    /// `navigate(to:)` with `.settings` pushes the settings view onto the stack navigator.
    func test_navigateTo_settings() throws {
        subject.navigate(to: .settings)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is SettingsView)
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

    /// `start()` navigates to the settings view.
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.last?.view is SettingsView)
    }
}

class MockSettingsCoordinatorDelegate: SettingsCoordinatorDelegate {
    var didLockVaultCalled = false
    var didLogoutCalled = false

    func didLockVault(account: Account) {
        didLockVaultCalled = true
    }

    func didLogout() {
        didLogoutCalled = true
    }
}
