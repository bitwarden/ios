// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class PendingRequestsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PendingRequestsState, PendingRequestsAction, PendingRequestsEffect>!
    var subject: PendingRequestsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: PendingRequestsState())
        let store = Store(processor: processor)

        subject = PendingRequestsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        processor.state.loadingState = .data([])
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The view with requests renders correctly.
    @MainActor
    func disabletest_snapshot_requests() {
        processor.state.loadingState = .data([
            .fixture(fingerprintPhrase: "pineapple-on-pizza-is-the-best", id: "1"),
            .fixture(fingerprintPhrase: "coconuts-are-underrated", id: "2"),
        ])
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
