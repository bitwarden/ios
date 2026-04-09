// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

// MARK: - SelectLanguageViewTests

class SelectLanguageViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SelectLanguageState, SelectLanguageAction, Void>!
    var subject: SelectLanguageView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SelectLanguageState())
        let store = Store(processor: processor)

        subject = SelectLanguageView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Test that the default view renders correctly.
    func disabletest_snapshot_default() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(),
            ],
        )
    }
}
