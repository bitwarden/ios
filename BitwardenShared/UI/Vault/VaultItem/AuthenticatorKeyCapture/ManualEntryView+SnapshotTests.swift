// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - ManualEntryViewTests

class ManualEntryViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ManualEntryState, ManualEntryAction, ManualEntryEffect>!
    var subject: ManualEntryView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: DefaultEntryState(deviceSupportsCamera: true))
        let store = Store(processor: processor)
        subject = ManualEntryView(
            store: store,
        )
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Test a snapshot of the `ManualEntryView` empty state.
    @MainActor
    func test_snapshot_manualEntryView_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultLandscape,
                .defaultPortraitDark,
            ],
        )
    }

    /// Test a snapshot of the `ManualEntryView` with text added.
    @MainActor
    func test_snapshot_manualEntryView_text() {
        processor.state.authenticatorKey = "manualEntry"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 1.75),
            ],
        )
    }
}
