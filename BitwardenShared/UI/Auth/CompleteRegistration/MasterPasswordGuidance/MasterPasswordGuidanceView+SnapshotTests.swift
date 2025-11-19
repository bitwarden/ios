// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class MasterPasswordGuidanceViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<Void, MasterPasswordGuidanceAction, Void>!
    var subject: MasterPasswordGuidanceView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ())

        subject = MasterPasswordGuidanceView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The master password guidance view renders correctly.
    @MainActor
    func disabletest_snapshot_masterPasswordGuidance() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 2),
                .defaultLandscape,
            ],
        )
    }
}
