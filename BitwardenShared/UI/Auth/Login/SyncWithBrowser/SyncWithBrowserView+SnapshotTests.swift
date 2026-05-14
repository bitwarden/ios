// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class SyncWithBrowserViewSnapshotTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SyncWithBrowserState, SyncWithBrowserAction, SyncWithBrowserEffect>!
    var subject: SyncWithBrowserView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SyncWithBrowserState(
            vaultUrl: "https://example.bitwarden.com",
        ))
        let store = Store(processor: processor)

        subject = SyncWithBrowserView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The sync with browser view renders correctly.
    @MainActor
    func disabletest_snapshot_default() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
