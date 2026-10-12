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

    /// The edit floating action button is hidden when the Send is disabled/restricted.
    @MainActor
    func test_editItemFloatingActionButton_hiddenWhenRestricted() throws {
        processor.state = ViewSendItemState(sendView: .fixture(type: .text, disabled: true))

        XCTAssertThrowsError(
            try subject.inspect().find(floatingActionButtonWithAccessibilityIdentifier: "EditItemFloatingActionButton"),
        )
    }

    /// The restriction banner has no action button for a disabled File Send.
    @MainActor
    func test_restrictionBanner_disabledFileSend_noMakeACopy() throws {
        processor.state = ViewSendItemState(sendView: .fixture(type: .file, disabled: true))

        let banner = try subject.inspect().find(viewWithAccessibilityIdentifier: "ViewSendRestrictionBanner")
        XCTAssertNotNil(banner)
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.makeACopy))
    }

    /// The restriction banner is shown with the "Make a copy" action for a disabled Text Send whose
    /// type isn't restricted by policy, and tapping it sends the `.makeCopy` action.
    @MainActor
    func test_restrictionBanner_makeACopy_tap() async throws {
        processor.state = ViewSendItemState(sendView: .fixture(type: .text, disabled: true))

        let button = try subject.inspect().find(asyncButton: Localizations.makeACopy)
        try await button.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .makeCopy)
    }

    /// The restriction banner has no action button for a disabled Text Send whose type is restricted
    /// by policy.
    @MainActor
    func test_restrictionBanner_sendTypeRestricted_noMakeACopy() throws {
        processor.state = ViewSendItemState(sendView: .fixture(type: .text, disabled: true))
        processor.state.sendPolicyOptions = SendPolicyOptions(enforcedSendType: .file)

        let banner = try subject.inspect().find(viewWithAccessibilityIdentifier: "ViewSendRestrictionBanner")
        XCTAssertNotNil(banner)
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.makeACopy))
    }
}
