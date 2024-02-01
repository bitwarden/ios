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
    func test_addItemButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.add)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping the add a send button dispatches the `.addItemPressed` action.
    func test_addSendButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.addASend)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping the info button dispatches the `.infoButtonPressed` action.
    func test_infoButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.aboutSend)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .infoButtonPressed)
    }

    // MARK: Snapshots

    /// The view renders correctly when there are no items.
    func test_snapshot_empty_light() {
        processor.state = .empty
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders in dark mode correctly when there are no items.
    func test_snapshot_empty_dark() {
        processor.state = .empty
        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    /// The view renders in large accessibility sizes correctly when there are no items.
    func test_snapshot_empty_ax5() {
        processor.state = .empty
        assertSnapshot(of: subject, as: .defaultPortraitAX5)
    }

    /// The view renders correctly when the search results are empty.
    func test_snapshot_search_empty_light() {
        processor.state.searchResults = []
        processor.state.searchText = "Searching"
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders in dark mode correctly when the search results are empty.
    func test_snapshot_search_empty_dark() {
        processor.state.searchResults = []
        processor.state.searchText = "Searching"
        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    /// The view renders in large accessibility correctly when the search results are empty.
    func test_snapshot_search_empty_ax5() {
        processor.state.searchResults = []
        processor.state.searchText = "Searching"
        assertSnapshot(of: subject, as: .defaultPortraitAX5)
    }

    /// The view renders correctly when there are search results.
    func test_snapshot_search_results_light() {
        processor.state = .hasSearchResults
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders in dark mode correctly when there are search results.
    func test_snapshot_search_results_dark() {
        processor.state = .hasSearchResults
        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    /// The view renders in large accessibility correctly when there are search results.
    func test_snapshot_search_results_ax5() {
        processor.state = .hasSearchResults
        assertSnapshot(of: subject, as: .defaultPortraitAX5)
    }

    /// The view renders in light mode correctly when there are sends.
    func test_snapshot_values_light() {
        processor.state = .content
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders in dark mode correctly when there are sends.
    func test_snapshot_values_dark() {
        processor.state = .content
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders in large accessibility sizes correctly when there are sends.
    func test_snapshot_values_ax5() {
        processor.state = .content
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders in light mode correctly when there are sends.
    func test_snapshot_textValues_light() {
        processor.state = .contentTextType
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders in dark mode correctly when there are sends.
    func test_snapshot_textValues_dark() {
        processor.state = .contentTextType
        assertSnapshot(of: subject, as: .defaultPortraitDark, record: true)
    }

    /// The view renders in large accessibility sizes correctly when there are sends.
    func test_snapshot_textValues_ax5() {
        processor.state = .contentTextType
        assertSnapshot(of: subject, as: .defaultPortraitAX5, record: true)
    }
}
