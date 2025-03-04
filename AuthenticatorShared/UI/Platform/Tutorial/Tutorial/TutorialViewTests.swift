import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import AuthenticatorShared

// MARK: - TutorialViewTests

class TutorialViewTests: AuthenticatorTestCase {
    // MARK: Properties

    var processor: MockProcessor<TutorialState, TutorialAction, TutorialEffect>!
    var subject: TutorialView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = TutorialState()
        processor = MockProcessor(state: state)
        subject = TutorialView(
            store: Store(processor: processor)
        )
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Test a snapshot of the ItemListView previews.
    func test_snapshot_TutorialView_previews() {
        for preview in TutorialView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [
                    .defaultPortrait,
                    .defaultPortraitDark,
                    .defaultLandscape,
                    .defaultPortraitAX5,
                    .defaultLandscapeAX5,
                ]
            )
        }
    }
}
