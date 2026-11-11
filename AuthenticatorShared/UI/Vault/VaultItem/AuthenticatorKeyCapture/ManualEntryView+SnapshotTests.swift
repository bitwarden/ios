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
    @MainActor
    func test_snapshot_manualEntryView_empty() {
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// Test a snapshot of the `ManualEntryView` empty state in landscape.
    @MainActor
    func test_snapshot_manualEntryView_empty_landscape() {
        assertSnapshot(of: subject.navStackWrapped, as: .defaultLandscape)
    }

    /// Test a snapshot of the `ManualEntryView` in dark mode.
    @MainActor
    func test_snapshot_manualEntryView_text_dark() {
        processor.state.authenticatorKey = "manualEntry"
        processor.state.name = "Manual Name"
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortraitDark)
    }

    /// Test a snapshot of the `ManualEntryView` with large text.
    @MainActor
    func test_snapshot_manualEntryView_text_largeText() {
        processor.state.authenticatorKey = "manualEntry"
        processor.state.name = "Manual Name"
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortraitAX5(heightMultiple: 1.75))
    }

    /// Test a snapshot of the `ManualEntryView` in light mode.
    @MainActor
    func test_snapshot_manualEntryView_text_light() {
        processor.state.authenticatorKey = "manualEntry"
        processor.state.name = "Manual Name"
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// Test a snapshot of the `ManualEntryView` in dark mode with the
    /// password manager sync flag active.
    @MainActor
    func test_snapshot_manualEntryView_text_dark_syncActive() {
        processor.state.defaultSaveOption = .none
        processor.state.isPasswordManagerSyncActive = true
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortraitDark)
    }

    /// Test a snapshot of the `ManualEntryView` with large text with the
    /// password manager sync flag active.
    @MainActor
    func test_snapshot_manualEntryView_text_largeText_syncActive() {
        processor.state.defaultSaveOption = .none
        processor.state.isPasswordManagerSyncActive = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortraitAX5(heightMultiple: 1.75))
    }

    /// Test a snapshot of the `ManualEntryView` in light mode with the
    /// password manager sync flag active.
    @MainActor
    func test_snapshot_manualEntryView_text_light_syncActive() {
        processor.state.defaultSaveOption = .none
        processor.state.isPasswordManagerSyncActive = true
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// Test a snapshot of the `ManualEntryView` with password manager sync active and
    /// Bitwarden as the default save location.
    @MainActor
    func test_snapshot_manualEntryView_syncActive_bitwardenDefault() {
        processor.state.defaultSaveOption = .saveToBitwarden
        processor.state.isPasswordManagerSyncActive = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Test a snapshot of the `ManualEntryView` with password manager sync active and
    /// this app as the default save location.
    @MainActor
    func test_snapshot_manualEntryView_syncActive_localDefault() {
        processor.state.defaultSaveOption = .saveHere
        processor.state.isPasswordManagerSyncActive = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
