import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - BitwardenTabBarControllerTests

class BitwardenTabBarControllerTests: BitwardenTestCase {
    /// Tests that the tab bar items are laid out correctly with valut selected (default).
    func test_snapshot_tabBarItems_vaultSelected() {
        let subject = BitwardenTabBarController()
        assertSnapshot(of: subject, as: .image)
    }

    /// Tests that the tab bar items are laid out correctly with send selected.
    func test_snapshot_tabBarItems_sendSelected() {
        let subject = BitwardenTabBarController()
        subject.selectedIndex = 1
        assertSnapshot(of: subject, as: .image)
    }

    /// Tests that the tab bar items are laid out correctly with generator selected.
    func test_snapshot_tabBarItems_generatorSelected() {
        let subject = BitwardenTabBarController()
        subject.selectedIndex = 2
        assertSnapshot(of: subject, as: .image)
    }

    /// Tests that the tab bar items are laid out correctly with settings selected.
    func test_snapshot_tabBarItems_settingsSelected() {
        let subject = BitwardenTabBarController()
        subject.selectedIndex = 3
        assertSnapshot(of: subject, as: .image)
    }
}
