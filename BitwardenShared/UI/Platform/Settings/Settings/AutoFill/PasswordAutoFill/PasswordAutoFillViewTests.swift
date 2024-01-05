import SnapshotTesting
import XCTest

@testable import BitwardenShared

class PasswordAutoFillViewTests: BitwardenTestCase {
    // MARK: Properties

    var subject = PasswordAutoFillView()

    // MARK: Tests

    /// The view renders correctly.
    func test_view_render() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
