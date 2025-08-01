import BitwardenResources
import BitwardenSdk
import SnapshotTesting
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
        let button = try subject.inspect().find(button: Localizations.close)
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

    // MARK: Snapshots

    /// Test a snapshot of the generator history view's empty state.
    func test_snapshot_generatorHistoryViewEmpty() {
        assertSnapshot(
            of: subject,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the generator history displaying a list of generated values.
    @MainActor
    func test_snapshot_generatorHistoryViewList() {
        processor.state.passwordHistory = [
            PasswordHistoryView(
                password: "8gr6uY8CLYQwzr#",
                lastUsedDate: Date(year: 2023, month: 11, day: 1, hour: 8, minute: 30)
            ),
            PasswordHistoryView(
                password: "%w4&D*48&CD&j2",
                lastUsedDate: Date(year: 2023, month: 10, day: 20, hour: 11, minute: 42)
            ),
            PasswordHistoryView(
                password: "03n@5bq!fw5k1!5cdfad6wes1u05b3hls$kbko&d#if4%cckowywt7sh8d*3%cxng553l&4" +
                    "7e4ywrt3l%dl537sonc6iw2*#r#*grwiw1@%#czm6ox64@m9u%im21*u#",
                lastUsedDate: Date(year: 2023, month: 0, day: 14, hour: 18, minute: 24)
            ),
        ]
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitAX5]
        )
    }
}
