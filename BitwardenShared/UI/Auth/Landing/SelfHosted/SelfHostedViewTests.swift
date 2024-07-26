import SnapshotTesting
import XCTest

@testable import BitwardenShared

class SelfHostedViewTests: BitwardenTestCase {
    let subject = SelfHostedView(store: Store(processor: StateProcessor(state: SelfHostedState())))

    /// Tests that the view renders correctly.
    func test_viewRender() {
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }
}
