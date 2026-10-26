// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessApprovalViewTests

class AgentAccessApprovalViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AgentAccessApprovalState, AgentAccessApprovalAction, AgentAccessApprovalEffect>!
    var subject: AgentAccessApprovalView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentAccessApprovalState(
            requestId: "request-1",
            candidates: [
                AgentAccessUIFixtures.candidate(id: "cipher-1", name: "Example"),
                AgentAccessUIFixtures.candidate(id: "cipher-2", name: "Example work", username: "work@example.com"),
            ],
            connectionFingerprint: AgentAccessUIFixtures.fingerprint,
            connectionName: "Codex",
            query: .domain("example.com"),
            secondsRemaining: 90,
            selectedCipherId: "cipher-1",
            status: .pending,
        ))
        subject = AgentAccessApprovalView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The loading state renders correctly.
    @MainActor
    func disabletest_snapshot_loading() {
        processor.state.status = .loading
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }

    /// A request with one matching login renders correctly.
    @MainActor
    func disabletest_snapshot_oneCandidate() {
        processor.state.candidates = [AgentAccessUIFixtures.candidate(id: "cipher-1", name: "Example")]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// A request with many matching logins renders correctly.
    @MainActor
    func disabletest_snapshot_manyCandidates() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// A request that is remembered for a time renders correctly.
    @MainActor
    func disabletest_snapshot_autoApprove() {
        processor.state.isAutoApproveOn = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }

    /// A request with no matching logins renders correctly.
    @MainActor
    func disabletest_snapshot_noCandidates() {
        processor.state.candidates = []
        processor.state.selectedCipherId = nil
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The expired state renders correctly.
    @MainActor
    func disabletest_snapshot_expired() {
        processor.state.status = .expired
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()],
        )
    }
}
