import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AutoFillViewTests: BitwardenTestCase {
    // MARK: Properties

    var subject = AutoFillView(store: Store(processor: StateProcessor(state: AutoFillState())))

    // MARK: Tests

    /// The view renders correctly.
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
