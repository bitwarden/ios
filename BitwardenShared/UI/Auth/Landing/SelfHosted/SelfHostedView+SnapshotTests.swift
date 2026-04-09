// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class SelfHostedViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SelfHostedState, SelfHostedAction, SelfHostedEffect>!
    var subject: SelfHostedView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SelfHostedState())

        subject = SelfHostedView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Snapshots

    /// Tests that the view renders correctly.
    func disabletest_snapshot_viewRender() {
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }
}
