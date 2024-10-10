import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - VaultCoordinatorTests

class VaultCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var delegate: MockVaultCoordinatorDelegate!
    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: VaultCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        delegate = MockVaultCoordinatorDelegate()
        module = MockAppModule()
        stackNavigator = MockStackNavigator()
        subject = VaultCoordinator(
            appExtensionDelegate: MockAppExtensionDelegate(),
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

    /// `handleEvent(_:context:)` with `.switchAccount` notifies the delegate to switch to the
    /// specified account.
    @MainActor
    func test_handleEvent_switchAccount() async {
        let route = AppRoute.tab(.vault(.vaultItemSelection(.fixtureExample)))
        await subject.handleEvent(.switchAccount(
            isAutomatic: true,
            userId: "1",
            authCompletionRoute: route
        ))

        XCTAssertTrue(delegate.switchedAccounts)
        XCTAssertEqual(delegate.switchAccountAuthCompletionRoute, route)
        XCTAssertTrue(delegate.switchAccountIsAutomatic)
        XCTAssertEqual(delegate.switchAccountUserId, "1")
    }

    /// `navigate(to:)` with `.autofillList` replaces the stack navigator's stack with the autofill list.
    @MainActor
    func test_navigateTo_autofillList() throws {
        subject.navigate(to: .autofillList)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is VaultAutofillListView)
    }

    /// `navigate(to:)` with `. addAccount ` informs the delegate that the user wants to add an account.
    @MainActor
    func test_navigateTo_addAccount() throws {
        subject.navigate(to: .addAccount)

        XCTAssertTrue(delegate.addAccountTapped)
    }

    /// `navigate(to:)` with `.addItem` presents the add item view onto the stack navigator.
    @MainActor
    func test_navigateTo_addItem() throws {
        let coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        module.vaultItemCoordinator = coordinator
        subject.navigate(to: .addItem())

        waitFor(!stackNavigator.actions.isEmpty)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(module.vaultItemCoordinator.routes.last, .addItem(hasPremium: true))
    }

    /// `.navigate(to:)` with `.editItem` presents the edit item screen.
    @MainActor
    func test_navigateTo_editItem() throws {
        subject.navigate(to: .editItem(.fixture()))

        waitFor(!stackNavigator.actions.isEmpty)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(module.vaultItemCoordinator.routes.last, .editItem(.fixture(), true))
    }

    /// `navigate(to:)` with `.dismiss` dismisses the top most view presented by the stack
    /// navigator.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.group` pushes the vault group view onto the stack navigator.
    @MainActor
    func test_navigateTo_group() throws {
        subject.navigate(to: .group(.identity, filter: .allVaults))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)

        let view = try XCTUnwrap((action.view as? UIHostingController<VaultGroupView>)?.rootView)
        XCTAssertEqual(view.store.state.group, .identity)
        XCTAssertEqual(view.store.state.vaultFilterType, .allVaults)
    }

    /// `navigate(to:)` with `.importLogins` presents the import logins view onto the stack navigator.
    @MainActor
    func test_navigateTo_importLogins() throws {
        subject.navigate(to: .importLogins)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<ImportLoginsView>)
    }

    /// `navigate(to:)` with `.list` pushes the vault list view onto the stack navigator.
    @MainActor
    func test_navigateTo_list_withoutPresented() throws {
        XCTAssertFalse(stackNavigator.isPresenting)
        subject.navigate(to: .list)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is VaultListView)
    }

    /// `navigate(to:)` with `.lockVault` navigates the user to the login view.
    @MainActor
    func test_navigateTo_lockVault() throws {
        let task = Task {
            await subject.handleEvent(.lockVault(userId: "123"))
        }
        waitFor(delegate.lockVaultId == "123")
        task.cancel()
    }

    /// `navigate(to:)` with `.loginRequest` calls the delegate method.
    @MainActor
    func test_navigateTo_loginRequest() {
        subject.navigate(to: .loginRequest(.fixture()))
        XCTAssertEqual(delegate.presentLoginRequestRequest, .fixture())
    }

    /// `navigate(to:)` with `.logout` informs the delegate that the user logged out.
    @MainActor
    func test_navigateTo_logout() throws {
        let task = Task {
            await subject.handleEvent(.logout(userId: "123", userInitiated: true))
        }

        waitFor(delegate.logoutTapped)
        task.cancel()
        let userInitiated = try XCTUnwrap(delegate.userInitiated)
        XCTAssertTrue(userInitiated)
    }

    /// `navigate(to:)` with `.logout` informs the delegate that the user logged out.
    @MainActor
    func test_navigateTo_logout_systemInitiated() throws {
        let task = Task {
            await subject.handleEvent(.logout(userId: "123", userInitiated: false))
        }

        waitFor(delegate.logoutTapped)
        task.cancel()
        let userInitiated = try XCTUnwrap(delegate.userInitiated)
        XCTAssertFalse(userInitiated)
    }

    /// `navigate(to:)` with `.switchAccount(userId:, isUnlocked: isUnlocked)`calls the associated delegate method.
    @MainActor
    func test_navigateTo_switchAccount() throws {
        subject.navigate(to: .switchAccount(userId: "123"))

        XCTAssertEqual(delegate.accountTapped, ["123"])
    }

    /// `.navigate(to:)` with `.vaultItemSelection` presents the vault item selection screen.
    @MainActor
    func test_navigateTo_vaultItemSelection() throws {
        let otpAuthModel = try XCTUnwrap(OTPAuthModel(otpAuthKey: .otpAuthUriKeyComplete))
        subject.navigate(to: .vaultItemSelection(otpAuthModel))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        XCTAssertTrue(navigationController.topViewController is UIHostingController<VaultItemSelectionView>)
    }

    /// `.navigate(to:)` with `.viewItem` presents the view item screen.
    @MainActor
    func test_navigateTo_viewItem() throws {
        subject.navigate(to: .viewItem(id: "id"))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(module.vaultItemCoordinator.routes.last, .viewItem(id: "id"))
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

    /// `start()` has no effect.
    @MainActor
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}

class MockVaultCoordinatorDelegate: VaultCoordinatorDelegate {
    var addAccountTapped = false
    var accountTapped = [String]()
    var lockVaultId: String?
    var logoutTapped = false
    var logoutUserId: String?
    var presentLoginRequestRequest: LoginRequest?
    var switchAccountAuthCompletionRoute: AppRoute?
    var switchAccountIsAutomatic = false
    var switchAccountUserId: String?
    var switchedAccounts = false
    var userInitiated: Bool?

    func lockVault(userId: String?) {
        lockVaultId = userId
    }

    func logout(userId: String?, userInitiated: Bool) {
        self.userInitiated = userInitiated
        logoutUserId = userId
        logoutTapped = true
    }

    func didTapAddAccount() {
        addAccountTapped = true
    }

    func didTapAccount(userId: String) {
        accountTapped.append(userId)
    }

    func presentLoginRequest(_ loginRequest: LoginRequest) {
        presentLoginRequestRequest = loginRequest
    }

    func switchAccount(userId: String, isAutomatic: Bool, authCompletionRoute: AppRoute?) {
        switchAccountAuthCompletionRoute = authCompletionRoute
        switchAccountIsAutomatic = isAutomatic
        switchAccountUserId = userId
        switchedAccounts = true
    }
}
