import SwiftUI
import XCTest

@testable import BitwardenShared

class AppModuleTests: BitwardenTestCase {
    // MARK: Properties

    var rootViewController: RootViewController!
    var subject: DefaultAppModule!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        rootViewController = RootViewController()
        subject = DefaultAppModule(services: .withMocks())
    }

    override func tearDown() {
        super.tearDown()

        rootViewController = nil
        subject = nil
    }

    // MARK: Tests

    /// `makeAppCoordinator` builds the app coordinator.
    @MainActor
    func test_makeAppCoordinator() {
        let coordinator = subject.makeAppCoordinator(appContext: .mainApp, navigator: rootViewController)
        let task = Task {
            coordinator.navigate(to: .auth(.landing), context: nil)
        }
        waitFor(rootViewController.childViewController != nil)
        task.cancel()
    }

    /// `makeAuthCoordinator` builds the auth coordinator.
    @MainActor
    func test_makeAuthCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeAuthCoordinator(
            delegate: MockAuthDelegate(),
            rootNavigator: rootViewController,
            stackNavigator: navigationController
        )
        coordinator.start()
        XCTAssertNotNil(rootViewController.childViewController)
        XCTAssertTrue(rootViewController.childViewController === navigationController)
    }

    /// `makeDebugMenuCoordinator()` builds the debug menu coordinator.
    @MainActor
    func test_makeDebugMenuCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeDebugMenuCoordinator(
            stackNavigator: navigationController
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<DebugMenuView>)
    }

    /// `makeExtensionSetupCoordinator` builds the extensions setup coordinator.
    @MainActor
    func test_makeExtensionSetupCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeExtensionSetupCoordinator(
            stackNavigator: navigationController
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<ExtensionActivationView>)
    }

    /// `makeSendCoordinator()` builds the send coordinator.
    @MainActor
    func test_makeSendCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeSendCoordinator(
            stackNavigator: navigationController
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<SendListView>)
    }

    /// `makeSendItemCoordinator()` builds the send item coordinator.
    @MainActor
    func test_makeSendItemCoordinator() {
        let delegate = MockSendItemDelegate()
        let navigationController = UINavigationController()
        let coordinator = subject.makeSendItemCoordinator(
            delegate: delegate,
            stackNavigator: navigationController
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 0)
    }

    /// `makeSettingsCoordinator()` builds the settings coordinator.
    @MainActor
    func test_makeSettingsCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeSettingsCoordinator(
            delegate: MockSettingsCoordinatorDelegate(),
            stackNavigator: navigationController
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<SettingsView>)
    }

    /// `makeTabCoordinator` builds the tab coordinator.
    @MainActor
    func test_makeTabCoordinator() {
        let errorReporter = MockErrorReporter()
        let tabBarController = UITabBarController()
        let settingsDelegate = MockSettingsCoordinatorDelegate()
        let vaultDelegate = MockVaultCoordinatorDelegate()
        let vaultRepository = MockVaultRepository()
        let coordinator = subject.makeTabCoordinator(
            errorReporter: errorReporter,
            rootNavigator: rootViewController,
            settingsDelegate: settingsDelegate,
            tabNavigator: tabBarController,
            vaultDelegate: vaultDelegate,
            vaultRepository: vaultRepository
        )
        coordinator.start()
        XCTAssertNotNil(rootViewController.childViewController)
        XCTAssertTrue(rootViewController.childViewController === tabBarController)
    }

    /// `makeVaultCoordinator()` builds the vault coordinator.
    @MainActor
    func test_makeVaultCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeVaultCoordinator(
            delegate: MockVaultCoordinatorDelegate(),
            stackNavigator: navigationController
        )
        coordinator.navigate(to: .list)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<VaultListView>)
    }
}
