import SnapshotTesting
import XCTest

@testable import BitwardenShared

class OtherSettingsViewTests: BitwardenTestCase {
    // MARK: Properties

    let subject = OtherSettingsView(store: Store(processor: StateProcessor(state: OtherSettingsState())))

    // MARK: Tests

    /// The view renders correctly.
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
