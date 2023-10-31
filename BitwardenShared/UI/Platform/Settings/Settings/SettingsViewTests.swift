import SnapshotTesting
import XCTest

// MARK: - SettingsViewTests

@testable import BitwardenShared

class SettingsViewTests: BitwardenTestCase {
    let subject = SettingsView(store: .mock(state: SettingsState()))

    /// Tests the view renders correctly.
    func testViewRender() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
