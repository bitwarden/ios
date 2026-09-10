// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
@preconcurrency import BitwardenSdk
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - SendListItemRowViewTests

class SendListItemRowViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SendListItemRowState, SendListItemRowAction, SendListItemRowEffect>!
    var subject: SendListItemRowView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(
            state: SendListItemRowState(
                item: SendListItem(id: "1", itemType: .send(.fixture(id: "1"))),
                hasDivider: false,
            ),
        )
        subject = SendListItemRowView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The options menu doesn't show an Edit option for a Send that's individually
    /// non-compliant (`sendView.disabled`), even when Sends aren't disabled org-wide.
    @MainActor
    func test_optionsMenu_disabledSend_hidesEdit() throws {
        processor.state.item = SendListItem(id: "1", itemType: .send(.fixture(id: "1", disabled: true)))

        let menu = try subject.inspect().find(ViewType.Menu.self) { view in
            try view.accessibilityIdentifier() == "SendOptionsButton"
        }
        XCTAssertThrowsError(try menu.find(button: Localizations.edit))
    }

    /// The options menu shows an Edit option for a compliant Send, and tapping it dispatches
    /// the `.editPressed` action.
    @MainActor
    func test_optionsMenu_enabledSend_editTapped() throws {
        let sendView = SendView.fixture(id: "1", disabled: false)
        processor.state.item = SendListItem(id: "1", itemType: .send(sendView))

        let menu = try subject.inspect().find(ViewType.Menu.self) { view in
            try view.accessibilityIdentifier() == "SendOptionsButton"
        }
        let button = try menu.find(button: Localizations.edit)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editPressed(sendView))
    }

    /// The options menu doesn't show an Edit option when Sends are disabled org-wide, even for
    /// a Send that isn't itself individually non-compliant.
    @MainActor
    func test_optionsMenu_sendsDisabledByPolicy_hidesEdit() throws {
        processor.state.isSendDisabled = true
        processor.state.item = SendListItem(id: "1", itemType: .send(.fixture(id: "1", disabled: false)))

        let menu = try subject.inspect().find(ViewType.Menu.self) { view in
            try view.accessibilityIdentifier() == "SendOptionsButton"
        }
        XCTAssertThrowsError(try menu.find(button: Localizations.edit))
    }
}
