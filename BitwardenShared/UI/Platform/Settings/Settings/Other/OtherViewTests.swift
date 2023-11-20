import SnapshotTesting
import XCTest

@testable import BitwardenShared

class OtherViewTests: BitwardenTestCase {
    // MARK: Properties

    let subject = OtherView(store: Store(processor: StateProcessor(state: OtherState())))

    // MARK: Tests

    /// The view renders correctly.
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
