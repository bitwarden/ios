// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessPairingViewTests

class AgentAccessPairingViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AgentAccessPairingState, AgentAccessPairingAction, AgentAccessPairingEffect>!
    var subject: AgentAccessPairingView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentAccessPairingState())
        subject = AgentAccessPairingView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The form renders correctly.
    @MainActor
    func disabletest_snapshot_form() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()],
        )
    }

    /// The token step renders correctly.
    @MainActor
    func disabletest_snapshot_token() {
        processor.state.pairing = AgentAccessUIFixtures.pairing(
            kind: .psk,
            token: String(repeating: "a", count: 64) + "_" + String(repeating: "b", count: 64),
        )
        processor.state.phase = .waiting
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The code step renders correctly.
    @MainActor
    func disabletest_snapshot_code() {
        processor.state.mode = .code
        processor.state.pairing = AgentAccessUIFixtures.pairing(kind: .rendezvous, token: "ABC-DEF-GHI")
        processor.state.phase = .waiting
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()],
        )
    }

    /// The fingerprint comparison renders correctly.
    @MainActor
    func disabletest_snapshot_verifying() {
        processor.state.phase = .verifying(AgentAccessFingerprintVerification(
            id: "verification-1",
            code: "a1b2c3",
            remoteFingerprint: AgentAccessUIFixtures.fingerprint,
        ))
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()],
        )
    }

    /// The rejected state renders correctly.
    @MainActor
    func disabletest_snapshot_rejected() {
        processor.state.phase = .rejected
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }
}
