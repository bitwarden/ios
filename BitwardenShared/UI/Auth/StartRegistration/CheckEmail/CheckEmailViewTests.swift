import BitwardenResources
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - CheckEmailViewTests

class CheckEmailViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<CheckEmailState, CheckEmailAction, Void>!
    var subject: CheckEmailView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: CheckEmailState(email: "example@email.com"))
        let store = Store(processor: processor)
        subject = CheckEmailView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissTapped)
    }

    /// Tapping the change email address button dispatches the `.goBackTapped` action.
    @MainActor
    func test_changeEmailAddressButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.changeEmailAddress)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .goBackTapped)
    }

    // MARK: Snapshots

    /// Tests the view renders correctly.
    func test_snapshot_empty() {
        assertSnapshots(
            of: subject,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(heightMultiple: 2),
            ]
        )
    }
}
