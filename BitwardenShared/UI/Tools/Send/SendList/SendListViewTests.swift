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

    /// Tapping the add an item button dispatches the `.addItemPressed` action.
    func test_addItemButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.add)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    /// Tapping the add a send button dispatches the `.addItemPressed` action.
    func test_addSendButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.addASend)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addItemPressed)
    }

    // MARK: Snapshots

    /// The view renders correctly when there are no items.
    func test_snapshot_empty() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    func test_snapshot_values() { // swiftlint:disable:this function_body_length
        let date = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41)
        processor.state.sections = [
            SendListSection(
                id: "1",
                isCountDisplayed: false,
                items: [
                    SendListItem(
                        id: "11",
                        itemType: .group(.text, 42)
                    ),
                    SendListItem(
                        id: "12",
                        itemType: .group(.file, 1)
                    ),
                ],
                name: "Types"
            ),
            SendListSection(
                id: "2",
                isCountDisplayed: true,
                items: [
                    SendListItem(
                        sendView: .init(
                            id: "21",
                            accessId: "21",
                            name: "File Send",
                            notes: nil,
                            key: "",
                            password: nil,
                            type: .file,
                            file: nil,
                            text: nil,
                            maxAccessCount: nil,
                            accessCount: 0,
                            disabled: false,
                            hideEmail: false,
                            revisionDate: date,
                            deletionDate: date.advanced(by: 100),
                            expirationDate: date.advanced(by: 100)
                        )
                    )!,
                    SendListItem(
                        sendView: .init(
                            id: "22",
                            accessId: "22",
                            name: "Text Send",
                            notes: nil,
                            key: "",
                            password: nil,
                            type: .text,
                            file: nil,
                            text: nil,
                            maxAccessCount: nil,
                            accessCount: 0,
                            disabled: false,
                            hideEmail: false,
                            revisionDate: date,
                            deletionDate: date.advanced(by: 100),
                            expirationDate: date.advanced(by: 100)
                        )
                    )!,
                    SendListItem(
                        sendView: .init(
                            id: "23",
                            accessId: "23",
                            name: "All Statuses",
                            notes: nil,
                            key: "",
                            password: "password",
                            type: .text,
                            file: nil,
                            text: nil,
                            maxAccessCount: 1,
                            accessCount: 1,
                            disabled: true,
                            hideEmail: true,
                            revisionDate: date,
                            deletionDate: date,
                            expirationDate: date.advanced(by: -1)
                        )
                    )!,
                ],
                name: "All sends"
            ),
        ]
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
