import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - VaultCoordinatorTests

class VaultCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var delegate: MockVaultCoordinatorDelegate!
    var errorReporter: MockErrorReporter!
    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var stateService: MockStateService!
    var subject: VaultCoordinator!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        delegate = MockVaultCoordinatorDelegate()
        module = MockAppModule()
        stateService = MockStateService()
        stackNavigator = MockStackNavigator()
        vaultRepository = MockVaultRepository()
        subject = VaultCoordinator(
            appExtensionDelegate: MockAppExtensionDelegate(),
            delegate: delegate,
            module: module,
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                stateService: stateService,
                vaultRepository: vaultRepository
            ),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        delegate = nil
        errorReporter = nil
        module = nil
        stackNavigator = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `didCompleteLoginsImport()` dismisses the import logins flow.
    @MainActor
    func test_didCompleteLoginsImport() throws {
        subject.didCompleteLoginsImport()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
    }

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
        XCTAssertEqual(
            module.vaultItemCoordinator.routes.last,
            .addItem(
                hasPremium: true,
                shouldShowLearnNewLoginActionCard: false
            )
        )
    }

    /// `navigate(to:)` with `.addItem` presents the add item view onto the stack navigator.
    @MainActor
    func test_navigateTo_addItem_showLearnNewLoginActionCard() throws {
        stateService.accounts = [Account.fixtureAccountLogin()]
        stateService.learnNewLoginActionCardStatus = .eligible
        vaultRepository.isVaultEmptyResult = .success(true)
        let coordinator = MockCoordinator<VaultItemRoute, VaultItemEvent>()
        module.vaultItemCoordinator = coordinator
        subject.navigate(to: .addItem())

        waitFor(!stackNavigator.actions.isEmpty)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(
            module.vaultItemCoordinator.routes.last,
            .addItem(
                hasPremium: true,
                shouldShowLearnNewLoginActionCard: true
            )
        )
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

    /// `.navigate(to:)` with `.editItemFrom` presents the edit item screen.
    @MainActor
    func test_navigateTo_editItemFrom() throws {
        vaultRepository.fetchCipherResult = .success(.fixture())
        subject.navigate(to: .editItemFrom(id: "1"))

        waitFor(!stackNavigator.actions.isEmpty)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(module.vaultItemCoordinator.routes.last, .editItem(.fixture(), true))
    }

    /// `.navigate(to:)` with `.editItemFrom` doesn't find the cipher id so it doesn't navigate there.
    @MainActor
    func test_navigateTo_editItemFromNotFound() throws {
        vaultRepository.fetchCipherResult = .success(nil)
        subject.navigate(to: .editItemFrom(id: "1"))

        XCTAssertTrue(stackNavigator.actions.isEmpty)
        XCTAssertTrue(!module.vaultItemCoordinator.isStarted)
    }

    /// `.navigate(to:)` with `.editItemFrom` throws fetching the cipher and it gets logged.
    @MainActor
    func test_navigateTo_editItemFromThrowsInternallyAndLogs() throws {
        vaultRepository.fetchCipherResult = .failure(BitwardenTestError.example)
        subject.navigate(to: .editItemFrom(id: "1"))

        waitFor(!errorReporter.errors.isEmpty)

        XCTAssertTrue(stackNavigator.actions.isEmpty)
        XCTAssertTrue(!module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `navigate(to:)` with `.dismiss` dismisses the top most view presented by the stack
    /// navigator.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.autofillListForGroup` pushes the vault autofill list view
    /// onto the stack navigator filtered by a group.
    @MainActor
    func test_navigateTo_autofillListForGroup() throws {
        subject.navigate(to: .autofillListForGroup(.identity))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)

        let view = try XCTUnwrap((action.view as? UIHostingController<VaultAutofillListView>)?.rootView)
        XCTAssertEqual(view.store.state.group, .identity)
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
        XCTAssertTrue(action.view is UINavigationController)
        XCTAssertTrue(module.importLoginsCoordinator.isStarted)
        XCTAssertEqual(module.importLoginsCoordinator.routes.last, .importLogins(.vault))
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
        XCTAssertFalse(delegate.hasManuallyLocked)
    }

    /// `navigate(to:)` with `.lockVault` calls the delegate to handle locking the vault manually.
    @MainActor
    func test_navigateTo_lockVaultManually() throws {
        let task = Task {
            await subject.handleEvent(.lockVault(userId: "123", isManuallyLocking: true))
        }
        waitFor(delegate.lockVaultId == "123")
        task.cancel()
        XCTAssertTrue(delegate.hasManuallyLocked)
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

    /// `navigate(to:)` with `.twoFactorNotice` presents the two-factor notice screen.
    @MainActor
    func test_navigateTo_twoFactorNotice() throws {
        subject.navigate(to: .twoFactorNotice(allowDelay: true, emailAddress: "person@example.com"))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.twoFactorNoticeCoordinator.isStarted)
        XCTAssertEqual(module.twoFactorNoticeCoordinator.routes.last, .emailAccess(allowDelay: true, emailAddress: "person@example.com"))
    }

    /// `.navigate(to:)` with `.vaultItemSelection` presents the vault item selection screen.
    @MainActor
    func test_navigateTo_vaultItemSelection() throws {
        subject.navigate(to: .vaultItemSelection(.fixtureExample))

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
    var hasManuallyLocked = false
    var lockVaultId: String?
    var logoutTapped = false
    var logoutUserId: String?
    var presentLoginRequestRequest: LoginRequest?
    var switchAccountAuthCompletionRoute: AppRoute?
    var switchAccountIsAutomatic = false
    var switchAccountUserId: String?
    var switchedAccounts = false
    var userInitiated: Bool?

    func lockVault(userId: String?, isManuallyLocking: Bool) {
        lockVaultId = userId
        hasManuallyLocked = isManuallyLocking
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
