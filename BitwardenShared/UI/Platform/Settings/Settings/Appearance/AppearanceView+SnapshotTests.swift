// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

// MARK: - AppearanceViewTests

@testable import BitwardenShared

class AppearanceViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AppearanceState, AppearanceAction, AppearanceEffect>!
    var subject: AppearanceView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AppearanceState())
        let store = Store(processor: processor)

        subject = AppearanceView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Tests the view renders correctly.
    func disabletest_snapshot_viewRender() {
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
