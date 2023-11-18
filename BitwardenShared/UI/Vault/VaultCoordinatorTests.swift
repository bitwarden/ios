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

    /// `navigate(to:)` with `. addAccount ` informs the delegate that the user wants to add an account.
    func test_navigateTo_addAccount() throws {
        subject.navigate(to: .addAccount)

        XCTAssertTrue(delegate.addAccountTapped)
    }

    /// `navigate(to:)` with `.addItem` pushes the add item view onto the stack navigator.
    func test_navigateTo_addItem() throws {
        subject.navigate(to: .addItem())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)

        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<AddItemView>)
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

    /// `navigate(to:)` with `.dismiss` dismisses the top most view presented by the stack
    /// navigator.
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
        XCTAssertEqual(action.dismissAll, false)
    }

    /// `navigate(to:)` with `.generator`, `.password`, and a delegate presents the generator
    /// screen.
    func test_navigateTo_generator_withPassword_withDelegate() throws {
        let generatorCoordinator = MockCoordinator<GeneratorRoute>()
        let delegate = MockGeneratorCoordinatorDelegate()
        module.generatorCoordinator = generatorCoordinator
        subject.navigate(to: .generator(.password), context: delegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(generatorCoordinator.isStarted)
        XCTAssertEqual(generatorCoordinator.routes.last, .generator(staticType: .password))
    }

    /// `navigate(to:)` with `.generator`, `.password`, and without a delegate does not present the
    /// generator screen.
    func test_navigateTo_generator_withPassword_withoutDelegate() throws {
        subject.navigate(to: .generator(.password), context: nil)

        XCTAssertNil(stackNavigator.actions.last)
    }

    /// `navigate(to:)` with `.generator`, `.username`, and a delegate presents the generator
    /// screen.
    func test_navigateTo_generator_withUsername_withDelegate() throws {
        let generatorCoordinator = MockCoordinator<GeneratorRoute>()
        let delegate = MockGeneratorCoordinatorDelegate()
        module.generatorCoordinator = generatorCoordinator
        subject.navigate(to: .generator(.username), context: delegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(generatorCoordinator.isStarted)
        XCTAssertEqual(generatorCoordinator.routes.last, .generator(staticType: .username))
    }

    /// `navigate(to:)` with `.generator`, `.username`, and without a delegate does not present the
    /// generator screen.
    func test_navigateTo_generator_withUsername_withoutDelegate() throws {
        subject.navigate(to: .generator(.username), context: nil)

        XCTAssertNil(stackNavigator.actions.last)
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

    /// `.navigate(to:)` with `.viewItem` presents the view item screen.
    func test_navigateTo_viewItem() throws {
        subject.navigate(to: .viewItem(id: "id"))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)

        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<ViewItemView>)
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

    /// `navigate(to:)` with `.setupTotpCamera` presents the camera screen.
    func test_navigateTo_setupTotpCamera() throws {
        subject.navigate(to: .setupTotpCamera)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is Text)
    }

    /// `start()` has no effect.
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}

class MockVaultCoordinatorDelegate: VaultCoordinatorDelegate {
    var addAccountTapped = false

    func didTapAddAccount() {
        addAccountTapped = true
    }
}
