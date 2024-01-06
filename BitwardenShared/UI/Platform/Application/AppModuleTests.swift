import SwiftUI
import XCTest

@testable import BitwardenShared

class AppModuleTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultAppModule!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultAppModule(services: .withMocks())
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `makeAppCoordinator` builds the app coordinator.
    func test_makeAppCoordinator() {
        let rootViewController = RootViewController()
        let coordinator = subject.makeAppCoordinator(appContext: .mainApp, navigator: rootViewController)
        coordinator.navigate(to: .auth(.landing), context: nil)
        XCTAssertNotNil(rootViewController.childViewController)
    }

    /// `makeAuthCoordinator` builds the auth coordinator.
    func test_makeAuthCoordinator() {
        let rootViewController = RootViewController()
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

    /// `makeSendCoordinator()` builds the send coordinator.
    func test_makeSendCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeSendCoordinator(
            stackNavigator: navigationController
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<SendListView>)
    }

    /// `makeSettingsCoordinator()` builds the settings coordinator.
    func test_makeSettingsCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeSettingsCoordinator(
            delegate: MockSettingsCoordinatorDelegate(),
            rootNavigator: MockRootNavigator(),
            stackNavigator: navigationController
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<SettingsView>)
    }

    /// `makeTabCoordinator` builds the tab coordinator.
    func test_makeTabCoordinator() {
        let rootViewController = RootViewController()
        let tabBarController = UITabBarController()
        let settingsDelegate = MockSettingsCoordinatorDelegate()
        let vaultDelegate = MockVaultCoordinatorDelegate()
        let coordinator = subject.makeTabCoordinator(
            rootNavigator: rootViewController,
            settingsDelegate: settingsDelegate,
            tabNavigator: tabBarController,
            vaultDelegate: vaultDelegate
        )
        coordinator.start()
        XCTAssertNotNil(rootViewController.childViewController)
        XCTAssertTrue(rootViewController.childViewController === tabBarController)
    }

    /// `makeVaultCoordinator()` builds the vault coordinator.
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
