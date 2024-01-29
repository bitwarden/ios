import XCTest

@testable import BitwardenShared

// MARK: - AppCoordinatorTests

@MainActor
class AppCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var module: MockAppModule!
    var rootNavigator: MockRootNavigator!
    var subject: AppCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        appExtensionDelegate = MockAppExtensionDelegate()
        module = MockAppModule()
        rootNavigator = MockRootNavigator()
        subject = AppCoordinator(
            appContext: .mainApp,
            appExtensionDelegate: appExtensionDelegate,
            module: module,
            rootNavigator: rootNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        appExtensionDelegate = nil
        module = nil
        rootNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `didCompleteAuth()` starts the tab coordinator and navigates to the proper tab route.
    func test_didCompleteAuth() {
        subject.didCompleteAuth()
        XCTAssertTrue(module.tabCoordinator.isStarted)
        XCTAssertEqual(module.tabCoordinator.routes, [.vault(.list)])
    }

    /// `didCompleteAuth()` starts the vault coordinator in the app extension and navigates to the
    /// proper vault route.
    func test_didCompleteAuth_appExtension() {
        subject = AppCoordinator(
            appContext: .appExtension,
            appExtensionDelegate: appExtensionDelegate,
            module: module,
            rootNavigator: rootNavigator
        )

        appExtensionDelegate.authCompletionRoute = .vault(.autofillList)
        subject.didCompleteAuth()
        XCTAssertTrue(module.vaultCoordinator.isStarted)
        XCTAssertEqual(module.vaultCoordinator.routes, [.autofillList])

        appExtensionDelegate.authCompletionRoute = .extensionSetup(.extensionActivation(type: .autofillExtension))
        subject.didCompleteAuth()
        XCTAssertTrue(module.vaultCoordinator.isStarted)
        XCTAssertEqual(module.vaultCoordinator.routes, [.autofillList])
    }

    /// `didDeleteAccount(otherAccounts:)` navigates to the landing screen
    /// and presents an alert notifying the user that they deleted their account.
    func test_didDeleteAccount_noOtherAccounts() {
        subject.didDeleteAccount(otherAccounts: [])
        XCTAssertEqual(module.authCoordinator.routes, [.landing, .alert(.accountDeletedAlert())])
    }

    /// `didDeleteAccount(otherAccounts:)` navigates to the vault unlock screen
    /// and presents an alert notifying the user that they deleted their account.
    func test_didDeleteAccount_otherAccounts() {
        let account: Account = .fixtureAccountLogin()
        subject.didDeleteAccount(otherAccounts: [account])
        XCTAssertEqual(
            module.authCoordinator.routes,
            [
                .vaultUnlock(
                    account,
                    didSwitchAccountAutomatically: true
                ),
                .alert(.accountDeletedAlert()),
            ]
        )
    }

    /// `didLockVault(_:, _:, _:)`  starts the auth coordinator and navigates to the login route.
    func test_did_lockVault() {
        let account: Account = .fixtureAccountLogin()

        subject.didLockVault(account: .fixtureAccountLogin())

        XCTAssertTrue(module.authCoordinator.isStarted)
        XCTAssertEqual(
            module.authCoordinator.routes,
            [
                .vaultUnlock(
                    account,
                    didSwitchAccountAutomatically: false
                ),
            ]
        )
    }

    /// `didLogout()` starts the auth coordinator and navigates to the landing route.
    func test_didLogout_automatic_nilAccounts() {
        subject.didLogout(userInitiated: false, otherAccounts: nil)
        XCTAssertTrue(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }

    /// `didLogout()` starts the auth coordinator and navigates to the landing route.
    func test_didLogout_automatic_noAccounts() {
        subject.didLogout(userInitiated: false, otherAccounts: [])
        XCTAssertTrue(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }

    /// `didLogout()` starts the auth coordinator and navigates to the landing route.
    func test_didLogout_automatic_withAccount() {
        subject.didLogout(userInitiated: false, otherAccounts: [.fixtureAccountLogin()])
        XCTAssertTrue(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }

    /// `didLogout()` starts the auth coordinator and navigates to the landing route.
    func test_didLogout_userInitiated_nilAccounts() {
        subject.didLogout(userInitiated: true, otherAccounts: nil)
        XCTAssertTrue(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }

    /// `didLogout()` starts the auth coordinator and navigates to the landing route.
    func test_didLogout_userInitiated_noAccounts() {
        subject.didLogout(userInitiated: true, otherAccounts: [])
        XCTAssertTrue(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }

    /// `didLogout()` starts the auth coordinator and navigates to the landing route.
    func test_didLogout_userInitiated_withAccount() {
        let altAccount = Account.fixtureAccountLogin()
        let expectedRoute = AuthRoute.vaultUnlock(
            altAccount,
            animated: true,
            attemptAutomaticBiometricUnlock: true,
            didSwitchAccountAutomatically: true
        )
        subject.didLogout(userInitiated: true, otherAccounts: [altAccount])
        XCTAssertTrue(module.authCoordinator.isStarted)
        XCTAssertEqual(
            module.authCoordinator.routes,
            [expectedRoute]
        )
    }

    /// `didTapAddAccount()` triggers the login sequence from the llanding page
    func test_didTapAddAccount() {
        subject.didTapAddAccount()
        XCTAssertTrue(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
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

    /// `navigate(to:)` with `.extensionSetup(.extensionActivation))` starts the extension setup
    /// coordinator and navigates to the proper route.
    func test_navigateTo_extensionSetup() throws {
        subject.navigate(to: .extensionSetup(.extensionActivation(type: .autofillExtension)))

        XCTAssertTrue(module.extensionSetupCoordinator.isStarted)
        XCTAssertEqual(module.extensionSetupCoordinator.routes, [.extensionActivation(type: .autofillExtension)])
    }

    /// `navigate(to:)` with `.extensionSetup(.extensionActivation))` twice uses the existing
    /// coordinator, rather than creating a new one.
    func test_navigateTo_extensionSetupTwice() {
        subject.navigate(to: .extensionSetup(.extensionActivation(type: .autofillExtension)))
        subject.navigate(to: .extensionSetup(.extensionActivation(type: .autofillExtension)))

        XCTAssertEqual(
            module.extensionSetupCoordinator.routes,
            [.extensionActivation(type: .autofillExtension), .extensionActivation(type: .autofillExtension)]
        )
    }

    /// `navigate(to:)` with `.sendItem(.add(content:hasPremium:))` starts the send item coordinator
    /// and navigates to the proper route.
    func test_navigateTo_sendItem() {
        subject.navigate(to: .sendItem(.add(content: nil, hasPremium: false)))

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(
            module.sendItemCoordinator.routes,
            [.add(content: nil, hasPremium: false)]
        )
    }

    /// `navigate(to:)` with `.sendItem()` twice uses the existing coordinator, rather than
    /// creating a new one.
    func test_navigateTo_sendItem_twice() {
        subject.navigate(to: .sendItem(.add(content: nil, hasPremium: false)))
        subject.navigate(to: .sendItem(.add(content: .text("test"), hasPremium: true)))

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(
            module.sendItemCoordinator.routes,
            [
                .add(content: nil, hasPremium: false),
                .add(content: .text("test"), hasPremium: true),
            ]
        )
    }

    /// `navigate(to:)` with `.tab(.vault(.list))` starts the tab coordinator and navigates to the proper tab route.
    func test_navigateTo_tab() {
        subject.navigate(to: .tab(.vault(.list)))
        XCTAssertTrue(module.tabCoordinator.isStarted)
        XCTAssertEqual(module.tabCoordinator.routes, [.vault(.list)])
    }

    /// `navigate(to:)` with `.tab(.vault(.list))` twice uses the existing coordinator, rather than creating a new one.
    func test_navigateTo_tabTwice() {
        subject.navigate(to: .tab(.vault(.list)))
        subject.navigate(to: .tab(.vault(.list)))

        XCTAssertEqual(module.tabCoordinator.routes, [.vault(.list), .vault(.list)])
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    func test_show_hide_loadingOverlay() throws {
        rootNavigator.rootViewController = UIViewController()
        try setKeyWindowRoot(viewController: XCTUnwrap(subject.rootNavigator.rootViewController))

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
