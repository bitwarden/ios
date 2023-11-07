import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - SendListViewTests

class SendListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SendListState, SendListAction, Void>!
    var subject: SendListView!

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SendListState())
        subject = SendListView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the add an item button dispatches the `.addItemPressed` action.
    func test_addItemButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.addAnItem)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping the add a send button dispatches the `.addItemPressed` action.
    func test_addSendButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.addASend)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    // MARK: Snapshots

    /// The view renders correctly when there are no items.
    func test_snapshot_empty() {
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }
}
