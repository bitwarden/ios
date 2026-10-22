// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessAuditLogViewTests

class AgentAccessAuditLogViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AgentAccessAuditLogState, AgentAccessAuditLogAction, AgentAccessAuditLogEffect>!
    var subject: AgentAccessAuditLogView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentAccessAuditLogState(
            entries: [
                AgentAccessUIFixtures.auditEntry(kind: .credentialApproved),
                AgentAccessUIFixtures.auditEntry(kind: .credentialDenied),
                AgentAccessUIFixtures.auditEntry(kind: .connectionEstablished, query: nil),
            ],
            isLoading: false,
        ))
        subject = AgentAccessAuditLogView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The activity renders correctly.
    @MainActor
    func disabletest_snapshot_entries() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The empty state renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        processor.state.entries = []
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()],
        )
    }
}
