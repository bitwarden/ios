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

    /// `navigate(to:)` with `.about` pushes the about view onto the stack navigator.
    func test_navigateTo_about() throws {
        subject.navigate(to: .about)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AboutView>)
    }

    /// `navigate(to:)` with `.accountSecurity` pushes the account security view onto the stack navigator.
    func test_navigateTo_accountSecurity() throws {
        subject.navigate(to: .accountSecurity)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AccountSecurityView>)
    }

    /// `navigate(to:)` with `.addEditFolder` pushes the add/edit folder view onto the stack navigator.
    func test_navigateTo_addEditFolder() throws {
        subject.navigate(to: .addEditFolder(folder: nil))

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<AddEditFolderView>)
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

    /// `navigate(to:)` with `.appearance` pushes the appearance view onto the stack navigator.
    func test_navigateTo_appearance() throws {
        subject.navigate(to: .appearance)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AppearanceView>)
    }

    /// `navigate(to:)` with `.appExtension` pushes the app extension view onto the stack navigator.
    func test_navigateTo_appExtension() throws {
        subject.navigate(to: .appExtension)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AppExtensionView>)
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

    /// `navigate(to:)` with `.didDeleteAccount(otherAccounts:)` calls the delegate method
    /// that performs navigation post-deletion.
    func test_navigateTo_didDeleteAccount() throws {
        subject.navigate(to: .didDeleteAccount(otherAccounts: []))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
        XCTAssertTrue(delegate.didDeleteAccountCalled)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the presented view.
    func test_navigateTo_dismiss() throws {
        subject.navigate(to: .dismiss)

        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissed)
    }

    /// `navigate(to:)` with `.exportVault` presents the export vault view.
    func test_navigateTo_exportVault() throws {
        subject.navigate(to: .exportVault)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<ExportVaultView>)
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

    /// `navigate(to:)` with `.folders` pushes the folders view onto the stack navigator.
    func test_navigateTo_folders() throws {
        subject.navigate(to: .folders)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<FoldersView>)
    }

    /// `navigate(to:)` with `.other` pushes the other view onto the stack navigator.
    func test_navigateTo_other() throws {
        subject.navigate(to: .other)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<OtherSettingsView>)
    }

    /// `navigate(to:)` with `.passwordAutoFill` pushes the password auto-fill view onto the stack navigator.
    func test_navigateTo_passwordAutoFill() throws {
        subject.navigate(to: .passwordAutoFill)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<PasswordAutoFillView>)
    }

    /// `navigate(to:)` with `.settings` pushes the settings view onto the stack navigator.
    func test_navigateTo_settings() throws {
        subject.navigate(to: .settings)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is SettingsView)
    }

    /// `navigate(to:)` with `.vault` pushes the vault settings view onto the stack navigator.
    func test_navigateTo_vault() throws {
        subject.navigate(to: .vault)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<VaultSettingsView>)
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
    var didDeleteAccountCalled = false
    var didLockVaultCalled = false
    var didLogoutCalled = false

    func didDeleteAccount(otherAccounts _: [Account]?) {
        didDeleteAccountCalled = true
    }

    func didLockVault(account _: Account) {
        didLockVaultCalled = true
    }

    func didLogout() {
        didLogoutCalled = true
    }
}
