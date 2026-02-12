// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class MigrateToMyItemsViewSnapshotTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<MigrateToMyItemsState, MigrateToMyItemsAction, MigrateToMyItemsEffect>!
    var subject: MigrateToMyItemsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: MigrateToMyItemsState(
            organizationId: "org-123",
            organizationName: "Acme Corporation",
        ))
        let store = Store(processor: processor)

        subject = MigrateToMyItemsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The transfer page renders correctly.
    @MainActor
    func disabletest_snapshot_transferPage() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The decline confirmation page renders correctly.
    @MainActor
    func disabletest_snapshot_declineConfirmationPage() {
        processor.state.page = .declineConfirmation
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
