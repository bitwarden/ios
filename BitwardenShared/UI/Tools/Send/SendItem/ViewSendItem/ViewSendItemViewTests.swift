import BitwardenResources
import SnapshotTesting
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
        let button = try subject.inspect().find(button: Localizations.cancel)
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
            floatingActionButtonWithAccessibilityIdentifier: "EditItemFloatingActionButton"
        )
        try await fab.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editItem)
    }

    // MARK: Snapshots

    /// The view send view for a file send renders correctly.
    @MainActor
    func test_snapshot_viewSend_file() {
        processor.state = ViewSendItemState(
            sendView: .fixture(
                name: "My text send",
                notes: "Private notes for the send",
                type: .file,
                file: .fixture(fileName: "photo_123.jpg", sizeName: "3.25 MB")
            ),
            shareURL: URL(string: "send.bitwarden.com/39ngaol3")
        )
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)]
        )
    }

    /// The view send view for a text send renders correctly.
    @MainActor
    func test_snapshot_viewSend_text() {
        processor.state = ViewSendItemState(
            sendView: .fixture(
                name: "My text send",
                notes: "Private notes for the send",
                text: .fixture(text: "Some text to send"),
            ),
            shareURL: URL(string: "send.bitwarden.com/39ngaol3")
        )
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)]
        )
    }

    /// The view send view with additional options expanded renders correctly.
    @MainActor
    func test_snapshot_viewSend_additionalOptionsExpanded() {
        processor.state = ViewSendItemState(
            isAdditionalOptionsExpanded: true,
            sendView: .fixture(
                name: "My text send",
                notes: "Private notes for the send",
                text: .fixture(text: "Some text to send"),
                maxAccessCount: 3,
            ),
            shareURL: URL(string: "send.bitwarden.com/39ngaol3")
        )
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)]
        )
    }
}
