import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AddItemViewTests

class AddItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AddItemState, AddItemAction, AddItemEffect>!
    var subject: AddItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: AddItemState())
        let store = Store(processor: processor)
        subject = AddItemView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    // MARK: Snapshots

    func test_snapshot_empty() {
        assertSnapshot(of: subject, as: .tallPortrait)
    }
}
