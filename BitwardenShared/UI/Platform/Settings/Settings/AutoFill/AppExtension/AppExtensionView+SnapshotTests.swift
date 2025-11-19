// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AppExtensionViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AppExtensionState, AppExtensionAction, Void>!
    var subject: AppExtensionView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AppExtensionState())
        let store = Store(processor: processor)

        subject = AppExtensionView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The activate view renders correctly.
    @MainActor
    func disabletest_snapshot_appExtension_activate() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The almost done view renders correctly.
    @MainActor
    func disabletest_snapshot_appExtension_almostDone() {
        processor.state.extensionActivated = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The reactivate view renders correctly.
    @MainActor
    func disabletest_snapshot_appExtension_reactivate() {
        processor.state.extensionActivated = true
        processor.state.extensionEnabled = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
