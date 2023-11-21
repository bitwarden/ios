import SnapshotTesting
import XCTest

@testable import BitwardenShared

class DeleteAccountViewTests: BitwardenTestCase {
    // MARK: Properties

    let subject = DeleteAccountView(store: Store(processor: StateProcessor(state: DeleteAccountState())))

    // MARK: Tests

    /// The view renders correctly.
    func test_snapshot() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
