import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - SendListViewTests

class SendListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SendListState, SendListAction, SendListEffect>!
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
    @MainActor
    func test_addItemButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.add)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping the add item floating acrtion button dispatches the `.addItemPressed` action.`
    @MainActor
    func test_additemFloatingActionButton_tap() throws {
        let fab = try subject.inspect().find(viewWithAccessibilityLabel: "AddItemFloatingActionButton")
        try fab.button().tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping the add a send button dispatches the `.addItemPressed` action.
    @MainActor
    func test_addSendButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.addASend)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping the info button dispatches the `.infoButtonPressed` action.
    @MainActor
    func test_infoButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.aboutSend)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .infoButtonPressed)
    }

    // MARK: Snapshots

    /// The view renders correctly when there are no items.
    @MainActor
    func test_snapshot_empty() {
        processor.state = .empty
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultLandscape, .defaultPortraitAX5])
    }

    /// The view renders correctly when the search results are empty.
    @MainActor
    func test_snapshot_search_empty() {
        processor.state.searchResults = []
        processor.state.searchText = "Searching"
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The view renders correctly when there are search results.
    @MainActor
    func test_snapshot_search_results() {
        processor.state = .hasSearchResults
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The view renders correctly when there are sends.
    @MainActor
    func test_snapshot_values() {
        processor.state = .content
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The view renders in light mode correctly when there are sends.
    @MainActor
    func test_snapshot_textValues() {
        processor.state = .contentTextType
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultLandscape])
    }
}
