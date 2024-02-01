import SwiftUI
import XCTest

@testable import BitwardenShared

class SettingsCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var delegate: MockSettingsCoordinatorDelegate!
    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: SettingsCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        delegate = MockSettingsCoordinatorDelegate()
        module = MockAppModule()
        stackNavigator = MockStackNavigator()

        subject = SettingsCoordinator(
            delegate: delegate,
            module: module,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        delegate = nil
        module = nil
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

    /// `navigate(to:)` with `.appExtensionSetup` pushes the app extension view onto the stack navigator.
    func test_navigateTo_appExtensionSetup() throws {
        subject.navigate(to: .appExtensionSetup)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIActivityViewController)
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
        let task = Task {
            await subject.handleEvent(.didDeleteAccount)
        }

        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
        XCTAssertTrue(delegate.didDeleteAccountCalled)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.exportVault` presents the export vault view.
    func test_navigateTo_exportVault() throws {
        subject.navigate(to: .exportVault)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<ExportVaultView>)
    }

    /// `navigate(to:)` with `.lockVault` navigates the user to the login view.
    func test_navigateTo_lockVault() async throws {
        await subject.handleEvent(.authAction(.lockVault(userId: "")))

        XCTAssertTrue(delegate.didLockVaultCalled)
    }

    /// `navigate(to:)` with `.loginRequest` pushes the login request view onto the stack navigator.
    func test_navigateTo_loginRequest() throws {
        subject.navigate(to: .loginRequest(.fixture()))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.loginRequestCoordinator.isStarted)
        XCTAssertEqual(module.loginRequestCoordinator.routes.last, .loginRequest(.fixture()))
    }

    /// `navigate(to:)` with `.logout` informs the delegate that the user logged out.
    func test_navigateTo_logout_userInitiated() throws {
        let task = Task {
            await subject.handleEvent(.authAction(.logout(userId: "123", userInitiated: true)))
        }

        waitFor(delegate.didLogoutCalled)
        task.cancel()
        let userInitiated = try XCTUnwrap(delegate.wasLogoutUserInitiated)
        XCTAssertTrue(userInitiated)
    }

    /// `navigate(to:)` with `.logout` informs the delegate that the user logged out.
    func test_navigateTo_logout_systemInitiated() throws {
        let task = Task {
            await subject.handleEvent(.authAction(.logout(userId: "123", userInitiated: false)))
        }

        waitFor(delegate.didLogoutCalled)
        task.cancel()
        let userInitiated = try XCTUnwrap(delegate.wasLogoutUserInitiated)
        XCTAssertFalse(userInitiated)
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

    /// `navigate(to:)` with `.pendingLoginRequests()` presents the pending login requests view.
    func test_navigateTo_pendingLoginRequests() throws {
        subject.navigate(to: .pendingLoginRequests)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<PendingRequestsView>)
    }

    /// `navigate(to:)` with `.selectLanguage()` presents the select language view.
    func test_navigateTo_selectLanguage() throws {
        subject.navigate(to: .selectLanguage(currentLanguage: .default))

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<SelectLanguageView>)
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
    var lockedId: String?
    var loggedOutId: String?
    var switchAccountCalled = false
    var switchUserId: String?
    var wasLogoutUserInitiated: Bool?
    var wasSwitchAutomatic: Bool?

    func didDeleteAccount() {
        didDeleteAccountCalled = true
    }

    func lockVault(userId: String?) {
        lockedId = userId
        didLockVaultCalled = true
    }

    func logout(userId: String?, userInitiated: Bool) {
        loggedOutId = userId
        wasLogoutUserInitiated = userInitiated
        didLogoutCalled = true
    }

    func switchAccount(isAutomatic: Bool, userId: String) {
        switchAccountCalled = true
        wasSwitchAutomatic = isAutomatic
        switchUserId = userId
    }
}
