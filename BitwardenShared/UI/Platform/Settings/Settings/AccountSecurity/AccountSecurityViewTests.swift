import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AccountSecurityViewTests: BitwardenTestCase {
    // MARK: Properties

    var subject = AccountSecurityView(store: Store(processor: StateProcessor(state: AccountSecurityState())))

    // MARK: Snapshots

    /// The view renders correctly.
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
