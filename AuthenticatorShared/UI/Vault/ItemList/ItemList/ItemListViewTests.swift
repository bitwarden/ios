import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import AuthenticatorShared

// MARK: - ItemListViewTests

class ItemListViewTests: AuthenticatorTestCase {
    // MARK: Properties

    var processor: MockProcessor<ItemListState, ItemListAction, ItemListEffect>!
    var subject: ItemListView!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = ItemListState()
        processor = MockProcessor(state: state)
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
        subject = ItemListView(
            store: Store(processor: processor),
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// Test a snapshot of the ItemListView previews.
    func test_snapshot_ItemListView_previews() {
        for preview in ItemListView_Previews._allPreviews {
            assertSnapshots(
                matching: preview.content,
                as: [.defaultPortrait]
            )
        }
    }
}
