import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import XCTest

@testable import BitwardenShared

class SettingsCoordinatorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var configService: MockConfigService!
    var delegate: MockSettingsCoordinatorDelegate!
    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: SettingsCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        delegate = MockSettingsCoordinatorDelegate()
        module = MockAppModule()
        stackNavigator = MockStackNavigator()

        subject = SettingsCoordinator(
            delegate: delegate,
            module: module,
            services: ServiceContainer.withMocks(
                configService: configService
            ),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        delegate = nil
        module = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `didCompleteLoginsImport()` notifies the delegate that the user completed importing their
    /// logins and dismisses the import logins flow.
    @MainActor
    func test_didCompleteLoginsImport() throws {
        subject.didCompleteLoginsImport()

        XCTAssertTrue(delegate.didCompleteLoginsImportCalled)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.about` pushes the about view onto the stack navigator.
    @MainActor
    func test_navigateTo_about() throws {
        subject.navigate(to: .about)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AboutView>)
    }

    /// `navigate(to:)` with `.accountSecurity` pushes the account security view onto the stack navigator.
    @MainActor
    func test_navigateTo_accountSecurity() throws {
        subject.navigate(to: .accountSecurity)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AccountSecurityView>)
    }

    /// `navigate(to:)` with `.addEditFolder` starts the add/edit folder coordinator and navigates
    /// to the add/edit folder view.
    @MainActor
    func test_navigateTo_addEditFolder() throws {
        subject.navigate(to: .addEditFolder(folder: nil))

        XCTAssertTrue(module.addEditFolderCoordinator.isStarted)
        XCTAssertEqual(module.addEditFolderCoordinator.routes, [.addEditFolder(folder: nil)])
    }

    /// `navigate(to:)` with `.alert` has the stack navigator present the alert.
    @MainActor
    func test_navigateTo_alert() throws {
        let alert = Alert.defaultAlert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.genericErrorMessage
        )
        subject.showAlert(alert)

        XCTAssertEqual(stackNavigator.alerts, [alert])
    }

    /// `navigate(to:)` with `.appearance` pushes the appearance view onto the stack navigator.
    @MainActor
    func test_navigateTo_appearance() throws {
        subject.navigate(to: .appearance)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AppearanceView>)
    }

    /// `navigate(to:)` with `.appExtension` pushes the app extension view onto the stack navigator.
    @MainActor
    func test_navigateTo_appExtension() throws {
        subject.navigate(to: .appExtension)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AppExtensionView>)
    }

    /// `navigate(to:)` with `.appExtensionSetup` pushes the app extension view onto the stack navigator.
    @MainActor
    func test_navigateTo_appExtensionSetup() throws {
        subject.navigate(to: .appExtensionSetup)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIActivityViewController)
    }

    /// `navigate(to:)` with `.autoFill` pushes the auto-fill view onto the stack navigator.
    @MainActor
    func test_navigateTo_autoFill() throws {
        subject.navigate(to: .autoFill)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<AutoFillView>)
    }

    /// `navigate(to:)` with `.deleteAccount` presents the delete account view.
    @MainActor
    func test_navigateTo_deleteAccount() throws {
        subject.navigate(to: .deleteAccount)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is DeleteAccountView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `navigate(to:)` with `.didDeleteAccount(otherAccounts:)` calls the delegate method
    /// that performs navigation post-deletion.
    @MainActor
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
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.enableFlightRecorder` presents the enable flight recorder view.
    @MainActor
    func test_navigateTo_enableFlightRecorder() throws {
        subject.navigate(to: .enableFlightRecorder)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is EnableFlightRecorderView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `navigate(to:)` with `.exportVault` presents the export vault to file view when
    /// Credential Exchange flag to export is disabled.
    @MainActor
    func test_navigateTo_exportVaultCXPDisabled() async throws {
        configService.featureFlagsBool[.cxpExportMobile] = false
        let task = Task {
            subject.navigate(to: .exportVault)
        }
        defer { task.cancel() }

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return stackNavigator.actions.last?.view is ExportVaultView
        }

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is ExportVaultView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `navigate(to:)` with `.exportVault` presents the export settings view when
    /// Credential Exchange flag to export is enabled.
    @MainActor
    func test_navigateTo_exportVaultCXPEnabled() async throws {
        configService.featureFlagsBool[.cxpExportMobile] = true
        let task = Task {
            subject.navigate(to: .exportVault)
        }
        defer { task.cancel() }

        #if SUPPORTS_CXP

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return stackNavigator.actions.last != nil
        }

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<ExportSettingsView>)

        #else

        try await waitForAsync { [weak self] in
            guard let self else { return true }
            return stackNavigator.actions.last?.view is ExportVaultView
        }

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is ExportVaultView)
        XCTAssertEqual(action.embedInNavigationController, true)

        #endif
    }

    /// `navigate(to:)` with `.exportVaultToFile` presents the export vault to file view.
    @MainActor
    func test_navigateTo_exportVaultToFile() throws {
        subject.navigate(to: .exportVaultToFile)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is ExportVaultView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `navigate(to:)` with `.exportVaultToApp` presents the export vault
    /// to another app view (Credential Exchange flow) by starting its coordinator.
    @MainActor
    func test_navigateTo_exportVaultToApp() throws {
        subject.navigate(to: .exportVaultToApp)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)
        XCTAssertTrue(module.exportCXFCoordinator.isStarted)
    }

    /// `navigate(to:)` with `.importLogins` presents the import logins flow.
    @MainActor
    func test_navigateTo_importLogins() throws {
        subject.navigate(to: .importLogins)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)
        XCTAssertTrue(module.importLoginsCoordinator.isStarted)
        XCTAssertEqual(module.importLoginsCoordinator.routes.last, .importLogins(.settings))
    }

    /// `navigate(to:)` with `.flightRecorderLogs` presents the flight recorder logs view.
    @MainActor
    func test_navigateTo_flightRecorderLogs() throws {
        subject.navigate(to: .flightRecorderLogs)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is FlightRecorderLogsView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `navigate(to:)` with `.lockVault` navigates the user to the login view.
    @MainActor
    func test_navigateTo_lockVault() async throws {
        await subject.handleEvent(.authAction(.lockVault(userId: "")))

        XCTAssertTrue(delegate.didLockVaultCalled)
        XCTAssertFalse(delegate.hasManuallyLockedVault)
    }

    /// `navigate(to:)` with `.lockVault` calls the delegate to handle locking vault
    /// on manually locked.
    @MainActor
    func test_navigateTo_lockVaultManually() async throws {
        await subject.handleEvent(.authAction(.lockVault(userId: "", isManuallyLocking: true)))

        XCTAssertTrue(delegate.didLockVaultCalled)
        XCTAssertTrue(delegate.hasManuallyLockedVault)
    }

    /// `navigate(to:)` with `.loginRequest` pushes the login request view onto the stack navigator.
    @MainActor
    func test_navigateTo_loginRequest() throws {
        subject.navigate(to: .loginRequest(.fixture()))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.loginRequestCoordinator.isStarted)
        XCTAssertEqual(module.loginRequestCoordinator.routes.last, .loginRequest(.fixture()))
    }

    /// `navigate(to:)` with `.logout` informs the delegate that the user logged out.
    @MainActor
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
    @MainActor
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
    @MainActor
    func test_navigateTo_folders() throws {
        subject.navigate(to: .folders)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<FoldersView>)
    }

    /// `navigate(to:)` with `.other` pushes the other view onto the stack navigator.
    @MainActor
    func test_navigateTo_other() throws {
        subject.navigate(to: .other)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<OtherSettingsView>)
    }

    /// `navigate(to:)` with `.passwordAutoFill` pushes the password auto-fill view onto the stack navigator.
    @MainActor
    func test_navigateTo_passwordAutoFill() throws {
        subject.navigate(to: .passwordAutoFill)

        XCTAssertTrue(module.passwordAutoFillCoordinator.isStarted)
        XCTAssertEqual(module.passwordAutoFillCoordinator.routes, [.passwordAutofill(mode: .settings)])
        XCTAssertNil(module.passwordAutoFillCoordinatorDelegate)
        XCTAssertIdentical(module.passwordAutoFillCoordinatorStackNavigator, stackNavigator)
    }

    /// `navigate(to:)` with `.pendingLoginRequests()` presents the pending login requests view.
    @MainActor
    func test_navigateTo_pendingLoginRequests() throws {
        subject.navigate(to: .pendingLoginRequests)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is PendingRequestsView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `navigate(to:)` with `.selectLanguage()` presents the select language view.
    @MainActor
    func test_navigateTo_selectLanguage() throws {
        subject.navigate(to: .selectLanguage(currentLanguage: .default))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is SelectLanguageView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `navigate(to:)` with `.settings` pushes the settings view onto the stack navigator.
    @MainActor
    func test_navigateTo_settings() throws {
        subject.navigate(to: .settings(.tab))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is SettingsView)
    }

    /// `navigate(to:)` with `.shareURL(_:)` presents an activity view controller to share the URL.
    @MainActor
    func test_navigateTo_shareURL() throws {
        subject.navigate(to: .shareURL(.example))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIActivityViewController)
    }

    /// `navigate(to:)` with `.shareURL(_:)` presents an activity view controller to share the URLs.
    @MainActor
    func test_navigateTo_shareURLs() throws {
        subject.navigate(to: .shareURLs([.example]))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIActivityViewController)
    }

    /// `navigate(to:)` with `.vault` pushes the vault settings view onto the stack navigator.
    @MainActor
    func test_navigateTo_vault() throws {
        subject.navigate(to: .vault)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is UIHostingController<VaultSettingsView>)
    }

    /// `navigate(to:)` with `.vaultUnlockSetup` pushes the vault unlock setup screen.
    @MainActor
    func test_navigateTo_vaultUnlockSetup() throws {
        subject.navigate(to: .vaultUnlockSetup)

        XCTAssertEqual(module.authCoordinator.routes, [.vaultUnlockSetup(.settings)])
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    @MainActor
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
    @MainActor
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.last?.view is SettingsView)
    }

    /// `updateSettingsTabBadge(_:)` updates the badge value on the root view controller's tab bar item.
    @MainActor
    func test_updateSettingsTabBadge() {
        stackNavigator.rootViewController = UIViewController()

        subject.updateSettingsTabBadge("1")
        XCTAssertEqual(stackNavigator.rootViewController?.tabBarItem.badgeValue, "1")

        subject.updateSettingsTabBadge("2")
        XCTAssertEqual(stackNavigator.rootViewController?.tabBarItem.badgeValue, "2")

        subject.updateSettingsTabBadge(nil)
        XCTAssertNil(stackNavigator.rootViewController?.tabBarItem.badgeValue)
    }
}

class MockSettingsCoordinatorDelegate: SettingsCoordinatorDelegate {
    var didCompleteLoginsImportCalled = false
    var didDeleteAccountCalled = false
    var didLockVaultCalled = false
    var didLogoutCalled = false
    var hasManuallyLockedVault = false
    var lockedId: String?
    var loggedOutId: String?
    var switchAccountCalled = false
    var switchUserId: String?
    var wasLogoutUserInitiated: Bool?
    var wasSwitchAutomatic: Bool?

    func didCompleteLoginsImport() {
        didCompleteLoginsImportCalled = true
    }

    func didDeleteAccount() {
        didDeleteAccountCalled = true
    }

    func lockVault(userId: String?, isManuallyLocking: Bool) {
        lockedId = userId
        didLockVaultCalled = true
        hasManuallyLockedVault = isManuallyLocking
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
} // swiftlint:disable:this file_length
