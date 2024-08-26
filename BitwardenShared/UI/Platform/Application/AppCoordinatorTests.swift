import XCTest

@testable import BitwardenShared

// MARK: - AppCoordinatorTests

class AppCoordinatorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var module: MockAppModule!
    var rootNavigator: MockRootNavigator!
    var router: MockRouter<AuthEvent, AuthRoute>!
    var services: Services!
    var subject: AppCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        router = MockRouter(routeForEvent: { _ in .landing })
        module = MockAppModule()
        module.authRouter = router
        rootNavigator = MockRootNavigator()
        services = ServiceContainer.withMocks()

        subject = AppCoordinator(
            appContext: .mainApp,
            appExtensionDelegate: appExtensionDelegate,
            module: module,
            rootNavigator: rootNavigator,
            services: services
        )
    }

    override func tearDown() {
        super.tearDown()
        appExtensionDelegate = nil
        module = nil
        rootNavigator = nil
        services = nil
        subject = nil
    }

    // MARK: Tests

    /// `didCompleteAuth()` starts the tab coordinator and navigates to the proper tab route.
    @MainActor
    func test_didCompleteAuth() {
        subject.didCompleteAuth()
        XCTAssertTrue(module.tabCoordinator.isStarted)
        XCTAssertEqual(module.tabCoordinator.routes, [.vault(.list)])
    }

    /// `didCompleteAuth()` starts the vault coordinator in the app extension and navigates to the
    /// proper vault route.
    @MainActor
    func test_didCompleteAuth_appExtension() {
        subject = AppCoordinator(
            appContext: .appExtension,
            appExtensionDelegate: appExtensionDelegate,
            module: module,
            rootNavigator: rootNavigator,
            services: services
        )

        appExtensionDelegate.authCompletionRoute = .vault(.autofillList)
        subject.didCompleteAuth()
        XCTAssertTrue(module.vaultCoordinator.isStarted)
        XCTAssertEqual(module.vaultCoordinator.routes, [.autofillList])

        appExtensionDelegate.authCompletionRoute = .extensionSetup(.extensionActivation(type: .autofillExtension))
        subject.didCompleteAuth()
        XCTAssertTrue(module.vaultCoordinator.isStarted)
        XCTAssertEqual(module.vaultCoordinator.routes, [.autofillList])

        XCTAssertTrue(appExtensionDelegate.didCompleteAuthCalled)
    }

    /// `didCompleteAuth()` starts the tab coordinator and navigates to the vault list and the auth completion route.
    @MainActor
    func test_didCompleteAuth_authCompletionRoute() async {
        await subject.handleEvent(.setAuthCompletionRoute(.tab(.vault(.addAccount))))
        XCTAssertNotNil(subject.authCompletionRoute)

        subject.didCompleteAuth()

        XCTAssertTrue(module.tabCoordinator.isStarted)
        XCTAssertEqual(module.tabCoordinator.routes, [.vault(.list), .vault(.addAccount)])
        XCTAssertNil(subject.authCompletionRoute)
    }

    /// `didDeleteAccount(otherAccounts:)` navigates to the `didDeleteAccount` route.
    @MainActor
    func test_didDeleteAccount() throws {
        subject.didDeleteAccount()
        waitFor(!router.events.isEmpty)
        XCTAssertEqual(
            router.events,
            [
                .didDeleteAccount,
            ]
        )

        let alert = try XCTUnwrap(rootNavigator.alerts.last)
        XCTAssertEqual(alert, .accountDeletedAlert())
    }

    /// `lockVault(_:)` passes the lock event to the router.
    @MainActor
    func test_didLockVault() {
        let account: Account = .fixtureAccountLogin()

        subject.lockVault(userId: account.profile.userId)

        waitFor(module.authCoordinator.isStarted)
        waitFor(!router.events.isEmpty)
        XCTAssertEqual(
            router.events,
            [
                .action(.lockVault(userId: account.profile.userId)),
            ]
        )
    }

    /// `logout()` passes the event to the router.
    @MainActor
    func test_didLogout_automatic() {
        subject.logout(userId: "123", userInitiated: false)
        waitFor(module.authCoordinator.isStarted)
        XCTAssertEqual(router.events, [.action(.logout(userId: "123", userInitiated: false))])
    }

    /// `didLogout()` starts the auth coordinator and navigates to the `.didLogout` route.
    @MainActor
    func test_didLogout_userInitiated() {
        let expectedEvent = AuthEvent.action(.logout(userId: "123", userInitiated: true))
        subject.logout(userId: "123", userInitiated: true)
        waitFor(module.authCoordinator.isStarted)
        XCTAssertEqual(
            router.events,
            [expectedEvent]
        )
    }

    /// `didTapAccount(:)` triggers the switch account action.
    @MainActor
    func test_didTapAccount() {
        subject.didTapAccount(userId: "123")
        waitFor(module.authCoordinator.isStarted)
        XCTAssertEqual(
            router.events,
            [
                .action(
                    .switchAccount(
                        isAutomatic: false,
                        userId: "123"
                    )
                ),
            ]
        )
    }

    /// `didTapAddAccount()` triggers the login sequence from the landing page
    @MainActor
    func test_didTapAddAccount() {
        subject.didTapAddAccount()
        waitFor(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }

    /// `handle()` triggers the contained auth action.
    @MainActor
    func test_handleAuthAction() async {
        router.routeForEvent = { _ in .complete }
        await subject.handle(.switchAccount(isAutomatic: false, userId: "123"))
        waitFor(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.complete])
    }

    /// `handleEvent(_:)` navigates the user to the auth landing view.
    @MainActor
    func test_handleEvent_didLogout() async {
        await subject.handleEvent(.didLogout(userId: "1", userInitiated: false))
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }

    /// `navigate(to:)` with `.onboarding` starts the auth coordinator and navigates to the proper auth route.
    @MainActor
    func test_navigateTo_auth() throws {
        subject.navigate(to: .auth(.landing))

        waitFor(module.authCoordinator.isStarted)
        XCTAssertEqual(module.authCoordinator.routes, [.landing])
    }

    /// `navigate(to:)` with `.auth(.landing)` twice uses the existing coordinator, rather than creating a new one.
    @MainActor
    func test_navigateTo_authTwice() {
        subject.navigate(to: .auth(.landing))
        subject.navigate(to: .auth(.landing))

        waitFor(module.authCoordinator.routes.count > 1)
        XCTAssertEqual(module.authCoordinator.routes, [.landing, .landing])
    }

    /// `navigate(to:)` with `.extensionSetup(.extensionActivation))` starts the extension setup
    /// coordinator and navigates to the proper route.
    @MainActor
    func test_navigateTo_extensionSetup() throws {
        subject.navigate(to: .extensionSetup(.extensionActivation(type: .autofillExtension)))

        XCTAssertTrue(module.extensionSetupCoordinator.isStarted)
        XCTAssertEqual(module.extensionSetupCoordinator.routes, [.extensionActivation(type: .autofillExtension)])
    }

    /// `navigate(to:)` with `.extensionSetup(.extensionActivation))` twice uses the existing
    /// coordinator, rather than creating a new one.
    @MainActor
    func test_navigateTo_extensionSetupTwice() {
        subject.navigate(to: .extensionSetup(.extensionActivation(type: .autofillExtension)))
        subject.navigate(to: .extensionSetup(.extensionActivation(type: .autofillExtension)))

        XCTAssertEqual(
            module.extensionSetupCoordinator.routes,
            [.extensionActivation(type: .autofillExtension), .extensionActivation(type: .autofillExtension)]
        )
    }

    /// `navigate(to:)` with `.loginRequest(_)` shows the login request view.
    @MainActor
    func test_navigateTo_loginRequest() {
        // Set up.
        rootNavigator.rootViewController = MockUIViewController()
        subject.navigate(to: .tab(.vault(.list)))

        // Test.
        let task = Task {
            subject.navigate(to: .loginRequest(.fixture()))
        }
        waitFor((rootNavigator.rootViewController as? MockUIViewController)?.presentCalled == true)
        task.cancel()

        // Validate.
        XCTAssertTrue(
            (rootNavigator.rootViewController as? MockUIViewController)?.presentedView is UINavigationController
        )
        XCTAssertTrue(module.loginRequestCoordinator.isStarted)
        XCTAssertEqual(module.loginRequestCoordinator.routes.last, .loginRequest(.fixture()))
    }

    /// `navigate(to:)` with `.sendItem(.add(content:hasPremium:))` starts the send item coordinator
    /// and navigates to the proper route.
    @MainActor
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
    @MainActor
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
    @MainActor
    func test_navigateTo_tab() {
        subject.navigate(to: .tab(.vault(.list)))
        XCTAssertTrue(module.tabCoordinator.isStarted)
        XCTAssertEqual(module.tabCoordinator.routes, [.vault(.list)])
    }

    /// `navigate(to:)` with `.tab(.vault(.list))` twice uses the existing coordinator, rather than creating a new one.
    @MainActor
    func test_navigateTo_tabTwice() {
        subject.navigate(to: .tab(.vault(.list)))
        subject.navigate(to: .tab(.vault(.list)))

        XCTAssertEqual(module.tabCoordinator.routes, [.vault(.list), .vault(.list)])
    }

    /// `presentLoginRequest(_:)` shows the login request view.
    @MainActor
    func test_presentLoginRequest() {
        // Set up.
        rootNavigator.rootViewController = MockUIViewController()
        subject.navigate(to: .tab(.vault(.list)))

        // Test.
        let task = Task {
            subject.presentLoginRequest(.fixture())
        }
        waitFor((rootNavigator.rootViewController as? MockUIViewController)?.presentCalled == true)
        task.cancel()

        // Validate.
        XCTAssertTrue(
            (rootNavigator.rootViewController as? MockUIViewController)?.presentedView is UINavigationController
        )
        XCTAssertTrue(module.loginRequestCoordinator.isStarted)
        XCTAssertEqual(module.loginRequestCoordinator.routes.last, .loginRequest(.fixture()))
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    @MainActor
    func test_show_hide_loadingOverlay() throws {
        rootNavigator.rootViewController = UIViewController()
        try setKeyWindowRoot(viewController: XCTUnwrap(subject.rootNavigator?.rootViewController))

        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.showLoadingOverlay(LoadingOverlayState(title: "Loading..."))
        XCTAssertNotNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.hideLoadingOverlay()
        waitFor { window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag) == nil }
        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
    }

    /// `start()` doesn't navigate anywhere (first route is managed by AppProcessor).
    @MainActor
    func test_start() {
        subject.start()

        XCTAssertFalse(module.authCoordinator.isStarted)
    }

    /// `switchAccount(userId:isAutomatic:authCompletionRoute:)` sets the auth completion route and
    /// navigates to the appropriate route.
    @MainActor
    func test_switchAccount() throws {
        let authCompletionRoute = AppRoute.tab(.vault(.vaultItemSelection(.fixtureExample)))
        subject.switchAccount(
            userId: "1",
            isAutomatic: true,
            authCompletionRoute: authCompletionRoute
        )

        waitFor(!module.authCoordinator.routes.isEmpty)
        XCTAssertEqual(subject.authCompletionRoute, authCompletionRoute)
        XCTAssertEqual(
            router.events,
            [.action(.switchAccount(isAutomatic: true, userId: "1", authCompletionRoute: authCompletionRoute))]
        )
        XCTAssertEqual(module.authCoordinator.routes, [AuthRoute.landing])
    }
}
