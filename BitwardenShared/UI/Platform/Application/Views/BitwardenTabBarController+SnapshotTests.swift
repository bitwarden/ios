// swiftlint:disable:this file_name
import BitwardenKitMocks
import SnapshotTesting
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BitwardenTabBarControllerTests

class BitwardenTabBarControllerTests: BitwardenTestCase {
    var coordinator: TabCoordinator!
    var errorReporter: MockErrorReporter!
    var module: MockAppModule!
    var policyService: MockPolicyService!
    var rootNavigator: MockRootNavigator!
    var settingsDelegate: MockSettingsCoordinatorDelegate!
    var subject: BitwardenTabBarController!
    var vaultDelegate: MockVaultCoordinatorDelegate!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        module = MockAppModule()
        policyService = MockPolicyService()
        rootNavigator = MockRootNavigator()
        settingsDelegate = MockSettingsCoordinatorDelegate()
        vaultDelegate = MockVaultCoordinatorDelegate()
        vaultRepository = MockVaultRepository()
        subject = BitwardenTabBarController()

        coordinator = TabCoordinator(
            errorReporter: errorReporter,
            module: module,
            policyService: policyService,
            rootNavigator: rootNavigator,
            settingsDelegate: settingsDelegate,
            tabNavigator: subject,
            vaultDelegate: vaultDelegate,
            vaultRepository: vaultRepository,
        )

        coordinator.start()
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        module = nil
        policyService = nil
        rootNavigator = nil
        settingsDelegate = nil
        subject = nil
        vaultDelegate = nil
        vaultRepository = nil
    }

    /// Tests that the tab bar items are laid out correctly with vault selected (default) in light mode.
    func disabletest_snapshot_tabBarItems_vaultSelected_lightMode() {
        subject.overrideUserInterfaceStyle = .light
        assertSnapshot(of: subject, as: .standardImage)
    }

    /// Tests that the tab bar items are laid out correctly with vault selected (default) in dark mode.
    func disabletest_snapshot_tabBarItems_vaultSelected_darkMode() {
        subject.overrideUserInterfaceStyle = .dark
        assertSnapshot(of: subject, as: .standardImage)
    }

    /// Tests that the tab bar items are laid out correctly with send selected in light mode.
    func disabletest_snapshot_tabBarItems_sendSelected_lightMode() {
        subject.overrideUserInterfaceStyle = .light
        subject.selectedIndex = 1
        assertSnapshot(of: subject, as: .standardImage)
    }

    /// Tests that the tab bar items are laid out correctly with send selected in dark mode.
    func disabletest_snapshot_tabBarItems_sendSelected_darkMode() {
        subject.overrideUserInterfaceStyle = .dark
        subject.selectedIndex = 1
        assertSnapshot(of: subject, as: .standardImage)
    }

    /// Tests that the tab bar items are laid out correctly with generator selected in light mode.
    func disabletest_snapshot_tabBarItems_generatorSelected_lightMode() {
        subject.overrideUserInterfaceStyle = .light
        subject.selectedIndex = 2
        assertSnapshot(of: subject, as: .standardImage)
    }

    /// Tests that the tab bar items are laid out correctly with generator selected in dark mode.
    func disabletest_snapshot_tabBarItems_generatorSelected_darkMode() {
        subject.overrideUserInterfaceStyle = .dark
        subject.selectedIndex = 2
        assertSnapshot(of: subject, as: .standardImage)
    }

    /// Tests that the tab bar items are laid out correctly with settings selected in light mode.
    @MainActor
    func disabletest_snapshot_tabBarItems_settingsSelected_lightMode() {
        module.settingsNavigator?.rootViewController?.tabBarItem.badgeValue = "1"
        subject.overrideUserInterfaceStyle = .light
        subject.selectedIndex = 3
        assertSnapshot(of: subject, as: .standardImage)
    }

    /// Tests that the tab bar items are laid out correctly with settings selected in dark mode.
    @MainActor
    func disabletest_snapshot_tabBarItems_settingsSelected_darkMode() {
        module.settingsNavigator?.rootViewController?.tabBarItem.badgeValue = "1"
        subject.overrideUserInterfaceStyle = .dark
        subject.selectedIndex = 3
        assertSnapshot(of: subject, as: .standardImage)
    }
}
