import BitwardenResources
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

    /// Tapping the add item floating action button in the file type list performs the `.addItemPressed` effect.
    @MainActor
    func test_addItemFloatingActionButton_sendTypeFile_tap() async throws {
        processor.state.type = .file
        let fab = try subject.inspect().find(
            floatingActionButtonWithAccessibilityIdentifier: "AddItemFloatingActionButton"
        )
        try await fab.tap()
        XCTAssertEqual(processor.effects.last, .addItemPressed(.file))
    }

    /// Tapping the add item floating action button in the text type list performs the `.addItemPressed` effect.
    @MainActor
    func test_addItemFloatingActionButton_sendTypeText_tap() async throws {
        processor.state.type = .text
        let fab = try subject.inspect().find(
            floatingActionButtonWithAccessibilityIdentifier: "AddItemFloatingActionButton"
        )
        try await fab.tap()
        XCTAssertEqual(processor.effects.last, .addItemPressed(.text))
    }

    /// Tapping the add item floating action menu and selecting the file type performs the `.addItemPressed` effect.
    @MainActor
    func test_addItemFloatingActionMenu_file_tap() async throws {
        let fabMenuButton = try subject.inspect().find(asyncButton: Localizations.file)
        try await fabMenuButton.tap()
        XCTAssertEqual(processor.effects.last, .addItemPressed(.file))
    }

    /// Tapping the add item floating action menu and selecting the text type performs the `.addItemPressed` effect.
    @MainActor
    func test_addItemFloatingActionMenu_text_tap() async throws {
        let fabMenuButton = try subject.inspect().find(asyncButton: Localizations.text)
        try await fabMenuButton.tap()
        XCTAssertEqual(processor.effects.last, .addItemPressed(.text))
    }

    /// Tapping the add a send button in the empty state performs the `.addItemPressed` effect.
    @MainActor
    func test_emptyState_addSendButton_sendTypeFile_tap() async throws {
        processor.state = .empty
        processor.state.type = .file
        let button = try subject.inspect().find(asyncButton: Localizations.newSend)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .addItemPressed(.file))
    }

    /// Tapping the add a send button in the empty state performs the `.addItemPressed` effect.
    @MainActor
    func test_emptyState_addSendButton_sendTypeText_tap() async throws {
        processor.state = .empty
        processor.state.type = .text
        let button = try subject.inspect().find(asyncButton: Localizations.newSend)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .addItemPressed(.text))
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
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
            ]
        )
    }

    /// The view renders correctly when it's loading.
    @MainActor
    func test_snapshot_loading() {
        processor.state = .loading
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
            ]
        )
    }

    /// The view renders correctly when the search results are empty.
    @MainActor
    func test_snapshot_search_empty() {
        processor.state.searchResults = []
        processor.state.searchText = "Searching"
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
            ]
        )
    }

    /// The view renders correctly when there are search results.
    @MainActor
    func test_snapshot_search_results() {
        processor.state = .hasSearchResults
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
            ]
        )
    }

    /// The view renders in correctly when there are sends.
    @MainActor
    func test_snapshot_values() {
        processor.state = .content
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
            ]
        )
    }

    /// The view renders correctly when there are sends.
    @MainActor
    func test_snapshot_textValues() {
        processor.state = .contentTextType
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultLandscape,
                .defaultPortraitAX5,
            ]
        )
    }
}
