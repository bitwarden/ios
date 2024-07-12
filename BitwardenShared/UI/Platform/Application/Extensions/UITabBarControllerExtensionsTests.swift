import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - UITabBarControllerExtensionsTests

class UITabBarControllerExtensionsTests: BitwardenTestCase {
    var module: MockAppModule!
    var coordinator: TabCoordinator!
    var rootNavigator: MockRootNavigator!
    var vaultDelegate: MockVaultCoordinatorDelegate!
    var settingsDelegate: MockSettingsCoordinatorDelegate!
    var errorReporter: MockErrorReporter!
    var vaultRepository: MockVaultRepository!
    var subject: UITabBarController!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        module = MockAppModule()
        rootNavigator = MockRootNavigator()
        vaultDelegate = MockVaultCoordinatorDelegate()
        settingsDelegate = MockSettingsCoordinatorDelegate()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()
        subject = UITabBarController()

        coordinator = TabCoordinator(
            errorReporter: errorReporter,
            module: module,
            rootNavigator: rootNavigator,
            settingsDelegate: settingsDelegate,
            tabNavigator: subject,
            vaultDelegate: vaultDelegate,
            vaultRepository: vaultRepository
        )

        coordinator.start()
    }

    override func tearDown() {
        super.tearDown()

        module = nil
        coordinator = nil
        rootNavigator = nil
        vaultDelegate = nil
        settingsDelegate = nil
        errorReporter = nil
        vaultRepository = nil
        subject = nil
    }

    /// Tests that the tab bar items are laid out correctly with vault selected (default) in light mode.
    func test_snapshot_tabBarItems_vaultSelected_lightMode() {
        subject.overrideUserInterfaceStyle = .light
        assertSnapshot(of: subject, as: .image)
    }

    /// Tests that the tab bar items are laid out correctly with vault selected (default) in dark mode.
    func test_snapshot_tabBarItems_vaultSelected_darkMode() {
        subject.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: subject, as: .image)
    }

    /// Tests that the tab bar items are laid out correctly with send selected in light mode.
    func test_snapshot_tabBarItems_sendSelected_lightMode() {
        subject.overrideUserInterfaceStyle = .light
        subject.selectedIndex = 1
        assertSnapshot(of: subject, as: .image)
    }

    /// Tests that the tab bar items are laid out correctly with send selected in dark mode.
    func test_snapshot_tabBarItems_sendSelected_darkMode() {
        subject.overrideUserInterfaceStyle = .dark
        subject.selectedIndex = 1
        assertSnapshot(of: subject, as: .image)
    }

    /// Tests that the tab bar items are laid out correctly with generator selected in light mode.
    func test_snapshot_tabBarItems_generatorSelected_lightMode() {
        subject.overrideUserInterfaceStyle = .light
        subject.selectedIndex = 2
        assertSnapshot(of: subject, as: .image)
    }

    /// Tests that the tab bar items are laid out correctly with generator selected in dark mode.
    func test_snapshot_tabBarItems_generatorSelected_darkMode() {
        subject.overrideUserInterfaceStyle = .dark
        subject.selectedIndex = 2
        assertSnapshot(of: subject, as: .image)
    }

    /// Tests that the tab bar items are laid out correctly with settings selected in light mode.
    func test_snapshot_tabBarItems_settingsSelected_lightMode() {
        subject.overrideUserInterfaceStyle = .light
        subject.selectedIndex = 3
        assertSnapshot(of: subject, as: .image)
    }

    /// Tests that the tab bar items are laid out correctly with settings selected in dark mode.
    func test_snapshot_tabBarItems_settingsSelected_darkMode() {
        subject.overrideUserInterfaceStyle = .dark
        subject.selectedIndex = 3
        assertSnapshot(of: subject, as: .image)
    }
}
