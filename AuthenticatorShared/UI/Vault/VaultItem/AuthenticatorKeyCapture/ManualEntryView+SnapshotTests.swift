// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

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
    func disabletest_snapshot_manualEntryView_empty() {
        assertSnapshot(
            of: ManualEntryView_Previews.empty,
            as: .defaultPortrait,
        )
    }

    /// Test a snapshot of the `ManualEntryView` empty state.
    func disabletest_snapshot_manualEntryView_empty_landscape() {
        assertSnapshot(
            of: ManualEntryView_Previews.empty,
            as: .defaultLandscape,
        )
    }

    /// Test a snapshot of the `ManualEntryView` in dark mode.
    func disabletest_snapshot_manualEntryView_text_dark() {
        assertSnapshot(
            of: ManualEntryView_Previews.textAdded,
            as: .defaultPortraitDark,
        )
    }

    /// Test a snapshot of the `ManualEntryView` with large text.
    func disabletest_snapshot_manualEntryView_text_largeText() {
        assertSnapshot(
            of: ManualEntryView_Previews.textAdded,
            as: .tallPortraitAX5(heightMultiple: 1.75),
        )
    }

    /// Test a snapshot of the `ManualEntryView` in light mode.
    func disabletest_snapshot_manualEntryView_text_light() {
        assertSnapshot(
            of: ManualEntryView_Previews.textAdded,
            as: .defaultPortrait,
        )
    }

    /// Test a snapshot of the `ManualEntryView` in dark mode with the
    /// password manager sync flag active.
    func disabletest_snapshot_manualEntryView_text_dark_syncActive() {
        assertSnapshot(
            of: ManualEntryView_Previews.syncActiveNoDefault,
            as: .defaultPortraitDark,
        )
    }

    /// Test a snapshot of the `ManualEntryView` with large text with the
    /// password manager sync flag active.
    func disabletest_snapshot_manualEntryView_text_largeText_syncActive() {
        assertSnapshot(
            of: ManualEntryView_Previews.syncActiveNoDefault,
            as: .tallPortraitAX5(heightMultiple: 1.75),
        )
    }

    /// Test a snapshot of the `ManualEntryView` in light mode with the
    /// password manager sync flag active.
    func disabletest_snapshot_manualEntryView_text_light_syncActive() {
        assertSnapshot(
            of: ManualEntryView_Previews.syncActiveNoDefault,
            as: .defaultPortrait,
        )
    }

    /// Test a snapshot of the `ManualEntryView` previews.
    func disabletest_snapshot_manualEntryView_previews() {
        for preview in ManualEntryView_Previews._allPreviews {
            let name = preview.displayName ?? "Unknown"
            assertSnapshots(
                of: preview.content,
                as: [
                    "\(name)-portrait": .defaultPortrait,
                    "\(name)-portraitDark": .defaultPortraitDark,
                    "\(name)-portraitAX5": .defaultPortraitAX5,
                ],
            )
        }
    }
}
