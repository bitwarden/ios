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
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.autofillList` replaces the stack navigator's stack with the autofill list.
    func test_navigateTo_autofillList() throws {
        subject.navigate(to: .autofillList)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is VaultAutofillListView)
    }

    /// `navigate(to:)` with `. addAccount ` informs the delegate that the user wants to add an account.
    func test_navigateTo_addAccount() throws {
        subject.navigate(to: .addAccount)

        XCTAssertTrue(delegate.addAccountTapped)
    }

    /// `navigate(to:)` with `.addItem` presents the add item view onto the stack navigator.
    func test_navigateTo_addItem() throws {
        let coordinator = MockCoordinator<VaultItemRoute>()
        module.vaultItemCoordinator = coordinator
        let task = Task {
            subject.navigate(to: .addItem())
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(module.vaultItemCoordinator.asyncRoutes.last, .addItem())
    }

    /// `navigate(asyncTo:)` with `.addItem` presents the add item view onto the stack navigator.
    func test_navigateTo_addItem_async() throws {
        let coordinator = MockCoordinator<VaultItemRoute>()
        module.vaultItemCoordinator = coordinator
        let task = Task {
            await subject.navigate(asyncTo: .addItem())
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(module.vaultItemCoordinator.asyncRoutes.last, .addItem())
    }

    /// `navigate(to:)` with `.alert` presents the provided alert on the stack navigator.
    func test_navigate_alert() {
        let alert = BitwardenShared.Alert(
            title: "title",
            message: "message",
            preferredStyle: .alert,
            alertActions: [
                AlertAction(
                    title: "alert title",
                    style: .cancel
                ),
            ]
        )

        subject.navigate(to: .alert(alert))
        XCTAssertEqual(stackNavigator.alerts.last, alert)
    }

    /// `.navigate(to:)` with `.editItem` presents the edit item screen.
    func test_navigateTo_editItem() throws {
        subject.navigate(to: .editItem(cipher: .fixture()))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(module.vaultItemCoordinator.routes.last, .editItem(cipher: .fixture()))
    }

    /// `navigate(to:)` with `.dismiss` dismisses the top most view presented by the stack
    /// navigator.
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.group` pushes the vault group view onto the stack navigator.
    func test_navigateTo_group() throws {
        subject.navigate(to: .group(.identity))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)

        let view = try XCTUnwrap((action.view as? UIHostingController<VaultGroupView>)?.rootView)
        XCTAssertEqual(view.store.state.group, .identity)
    }

    /// `navigate(to:)` with `.list` pushes the vault list view onto the stack navigator.
    func test_navigateTo_list_withoutPresented() throws {
        XCTAssertFalse(stackNavigator.isPresenting)
        subject.navigate(to: .list)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is VaultListView)
    }

    /// `.navigate(to:)` with `.list` while presenting a screen modally dismisses the modal screen.
    func test_navigateTo_list_whilePresenting() throws {
        stackNavigator.present(EmptyView(), animated: false, overFullscreen: false)
        subject.navigate(to: .list)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.switchAccount(userId:, isUnlocked: isUnlocked)`calls the associated delegate method.
    func test_navigateTo_switchAccount() throws {
        subject.navigate(to: .switchAccount(userId: "123"))

        XCTAssertEqual(delegate.accountTapped, ["123"])
    }

    /// `.navigate(to:)` with `.viewItem` presents the view item screen.
    func test_navigateTo_viewItem() throws {
        subject.navigate(to: .viewItem(id: "id"))
        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(module.vaultItemCoordinator.asyncRoutes.last, .viewItem(id: "id"))
    }

    /// `.navigate(asyncTo:)` with `.viewItem` presents the view item screen.
    func test_navigateTo_viewItem_async() async throws {
        await subject.navigate(asyncTo: .viewItem(id: "id"))
        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(module.vaultItemCoordinator.isStarted)
        XCTAssertEqual(module.vaultItemCoordinator.asyncRoutes.last, .viewItem(id: "id"))
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

    /// `start()` has no effect.
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}

class MockVaultCoordinatorDelegate: VaultCoordinatorDelegate {
    var addAccountTapped = false
    var accountTapped = [String]()

    func didTapAddAccount() {
        addAccountTapped = true
    }

    func didTapAccount(userId: String) {
        accountTapped.append(userId)
    }
}
