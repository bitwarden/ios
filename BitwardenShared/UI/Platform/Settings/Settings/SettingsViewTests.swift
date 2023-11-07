import SnapshotTesting
import XCTest

// MARK: - SettingsViewTests

@testable import BitwardenShared

class SettingsViewTests: BitwardenTestCase {
    // MARK: Properties

    let subject = SettingsView(store: .mock(state: SettingsState()))

    /// Tests the view renders correctly.
    func test_viewRender() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
