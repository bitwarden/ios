// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessHomeViewTests

class AgentAccessHomeViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AgentAccessHomeState, AgentAccessHomeAction, AgentAccessHomeEffect>!
    var subject: AgentAccessHomeView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentAccessHomeState(
            autoApproveRules: [AgentAccessUIFixtures.autoApproveRule()],
            connectionsCount: 2,
            isListeningEnabled: true,
            relayURL: AgentAccessConstants.defaultRelayURL,
            relayURLInput: AgentAccessConstants.defaultRelayURL,
            status: .listening,
        ))
        subject = AgentAccessHomeView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The home screen with listening on renders correctly.
    @MainActor
    func disabletest_snapshot_listening() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The home screen with listening off renders correctly.
    @MainActor
    func disabletest_snapshot_off() {
        processor.state = AgentAccessHomeState(
            relayURL: AgentAccessConstants.defaultRelayURL,
            relayURLInput: AgentAccessConstants.defaultRelayURL,
        )
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }

    /// The home screen with an invalid relay server address renders correctly.
    @MainActor
    func disabletest_snapshot_relayURLError() {
        processor.state.relayURLInput = "http://example.com"
        processor.state.relayURLErrorMessage = "Enter a ws:// or wss:// address."
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }
}
