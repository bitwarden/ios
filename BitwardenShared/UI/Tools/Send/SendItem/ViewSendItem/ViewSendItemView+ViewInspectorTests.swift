// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

class ViewSendItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ViewSendItemState, ViewSendItemAction, ViewSendItemEffect>!
    var subject: ViewSendItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ViewSendItemState(sendView: .fixture()))

        subject = ViewSendItemView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button sends the `.dismiss` action.
    @MainActor
    func test_cancel_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the delete button performs the `.delete` effect.
    @MainActor
    func test_delete_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.deleteSend)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .deleteSend)
    }

    /// Tapping the edit button sends the `.editItem` action.
    @MainActor
    func test_editItemFloatingActionButton_tap() async throws {
        let fab = try subject.inspect().find(
            floatingActionButtonWithAccessibilityIdentifier: "EditItemFloatingActionButton",
        )
        try await fab.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editItem)
    }
}
