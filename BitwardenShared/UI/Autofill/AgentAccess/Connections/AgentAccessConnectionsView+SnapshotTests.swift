// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessConnectionsViewTests

class AgentAccessConnectionsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        AgentAccessConnectionsState,
        AgentAccessConnectionsAction,
        AgentAccessConnectionsEffect,
    >!
    var subject: AgentAccessConnectionsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentAccessConnectionsState(
            connections: [
                AgentAccessUIFixtures.connection(),
                AgentAccessUIFixtures.connection(fingerprint: String(repeating: "cd", count: 32), name: nil),
            ],
            isLoading: false,
        ))
        subject = AgentAccessConnectionsView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The list of connections renders correctly.
    @MainActor
    func disabletest_snapshot_connections() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The empty state renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        processor.state.connections = []
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()],
        )
    }
}
