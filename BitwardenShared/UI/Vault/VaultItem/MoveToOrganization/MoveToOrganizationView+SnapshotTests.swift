// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class MoveToOrganizationViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<MoveToOrganizationState, MoveToOrganizationAction, MoveToOrganizationEffect>!
    var subject: MoveToOrganizationView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: MoveToOrganizationState(cipher: .fixture()))
        let store = Store(processor: processor)

        subject = MoveToOrganizationView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Previews

    /// The empty view renders correctly.
    func disabletest_snapshot_moveToOrganization_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The collections view renders correctly.
    @MainActor
    func disabletest_snapshot_moveToOrganization_collections() {
        processor.state.collections = [
            .fixture(id: "1", name: "Design", organizationId: "1"),
            .fixture(id: "2", name: "Engineering", organizationId: "1"),
        ]
        processor.state.organizationId = "1"
        processor.state.ownershipOptions = [.organization(id: "1", name: "Organization")]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
