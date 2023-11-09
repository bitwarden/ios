import BitwardenSdk
import SnapshotTesting
import ViewInspector
import XCTest

import SwiftUI

@testable import BitwardenShared

class GeneratorHistoryViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<GeneratorHistoryState, GeneratorHistoryAction, Void>!
    var subject: GeneratorHistoryView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: GeneratorHistoryState())
        let store = Store(processor: processor)

        subject = GeneratorHistoryView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the clear button dispatches the `.clearList` action.
    func test_clear_tapped() throws {
        let menu = try subject.inspect().find(ViewType.Menu.self, containing: Localizations.options)
        let button = try menu.find(button: Localizations.clear)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .clearList)
    }

    /// Tapping the close button dispatches the `.dismiss` action.
    func test_close_tapped() throws {
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.close)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the copy button on a password history row dispatches the `.copyPassword` action.
    func test_copyPassword_tapped() throws {
        let passwordHistory = PasswordHistoryView(
            password: "8gr6uY8CLYQwzr#",
            lastUsedDate: Date(year: 2023, month: 11, day: 1, hour: 8, minute: 30)
        )
        processor.state.passwordHistory = [passwordHistory]

        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyPassword)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPassword(passwordHistory))
    }

    // MARK: Snapshots

    /// Test a snapshot of the generator history view's empty state.
    func test_snapshot_generatorHistoryViewEmpty() {
        assertSnapshot(
            matching: subject,
            as: .defaultPortrait
        )
    }

    /// Test a snapshot of the generator history displaying a list of generated values.
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
                password: "df@58^%8o7e@&@",
                lastUsedDate: Date(year: 2023, month: 0, day: 14, hour: 18, minute: 24)
            ),
        ]
        assertSnapshot(
            matching: subject,
            as: .defaultPortrait
        )
    }
}
