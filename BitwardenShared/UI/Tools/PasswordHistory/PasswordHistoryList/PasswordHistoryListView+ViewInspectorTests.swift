// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import ViewInspector
import XCTest

import SwiftUI

@testable import BitwardenShared

class PasswordHistoryListViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PasswordHistoryListState, PasswordHistoryListAction, PasswordHistoryListEffect>!
    var subject: PasswordHistoryListView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: PasswordHistoryListState())
        let store = Store(processor: processor)

        subject = PasswordHistoryListView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the clear button dispatches the `.clearList` action.
    @MainActor
    func test_clear_tapped() async throws {
        let menu = try subject.inspect().find(ViewType.Menu.self, containing: Localizations.options)
        let button = try menu.find(asyncButton: Localizations.clear)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .clearList)
    }

    /// Tapping the close button dispatches the `.dismiss` action.
    @MainActor
    func test_close_tapped() throws {
        let button = try subject.inspect().findCloseToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the copy button on a password history row dispatches the `.copyPassword` action.
    @MainActor
    func test_copyPassword_tapped() throws {
        let passwordHistory = PasswordHistoryView.fixture(password: "8gr6uY8CLYQwzr#")
        processor.state.passwordHistory = [passwordHistory]

        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyPassword)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPassword(passwordHistory))
    }
}
