// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

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
            floatingActionButtonWithAccessibilityIdentifier: "AddItemFloatingActionButton",
        )
        try await fab.tap()
        XCTAssertEqual(processor.effects.last, .addItemPressed(.file))
    }

    /// Tapping the add item floating action button in the text type list performs the `.addItemPressed` effect.
    @MainActor
    func test_addItemFloatingActionButton_sendTypeText_tap() async throws {
        processor.state.type = .text
        let fab = try subject.inspect().find(
            floatingActionButtonWithAccessibilityIdentifier: "AddItemFloatingActionButton",
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
}
