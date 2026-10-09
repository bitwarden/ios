// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - AgentFillApprovalViewTests

class AgentFillApprovalViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AgentFillApprovalState, AgentFillApprovalAction, AgentFillApprovalEffect>!
    var subject: AgentFillApprovalView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentFillApprovalState(
            approvalId: "approval-1",
            connectionName: "Claude Desktop",
            domain: "delta.com",
            browserName: "Chrome",
            items: [
                AgentFillApprovalItem(id: "cipher-1", name: "Delta", subtitle: "user@example.com"),
                AgentFillApprovalItem(id: "cipher-2", name: "Delta work", subtitle: "work@example.com"),
            ],
            selectedItemId: "cipher-1",
            status: .pending,
        ))
        subject = AgentFillApprovalView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The pending request renders correctly.
    @MainActor
    func disabletest_snapshot_pending() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 2),
            ],
        )
    }

    /// The pending request with no matching items renders correctly.
    @MainActor
    func disabletest_snapshot_noMatchingItems() {
        processor.state.items = []
        processor.state.selectedItemId = nil
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 2),
            ],
        )
    }

    /// The handled state renders correctly.
    @MainActor
    func disabletest_snapshot_handled() {
        processor.state.status = .handled
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(),
            ],
        )
    }

    /// The expired state renders correctly.
    @MainActor
    func disabletest_snapshot_expired() {
        processor.state.status = .expired
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(),
            ],
        )
    }
}
