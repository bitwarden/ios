// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
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

    // MARK: Snapshots

    /// The view send view for a file send renders correctly.
    @MainActor
    func disabletest_snapshot_viewSend_file() {
        processor.state = ViewSendItemState(
            sendView: .fixture(
                name: "My text send",
                notes: "Private notes for the send",
                type: .file,
                file: .fixture(fileName: "photo_123.jpg", sizeName: "3.25 MB"),
            ),
            shareURL: URL(string: "send.bitwarden.com/39ngaol3"),
        )
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The view send view for a text send renders correctly.
    @MainActor
    func disabletest_snapshot_viewSend_text() {
        processor.state = ViewSendItemState(
            sendView: .fixture(
                name: "My text send",
                notes: "Private notes for the send",
                text: .fixture(text: "Some text to send"),
            ),
            shareURL: URL(string: "send.bitwarden.com/39ngaol3"),
        )
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The view send view with additional options expanded renders correctly.
    @MainActor
    func disabletest_snapshot_viewSend_additionalOptionsExpanded() {
        processor.state = ViewSendItemState(
            isAdditionalOptionsExpanded: true,
            sendView: .fixture(
                name: "My text send",
                notes: "Private notes for the send",
                text: .fixture(text: "Some text to send"),
                maxAccessCount: 3,
            ),
            shareURL: URL(string: "send.bitwarden.com/39ngaol3"),
        )
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The view send view for a disabled file send renders correctly, with the send-link section
    /// and edit FAB hidden and no "Make a copy" action.
    @MainActor
    func disabletest_snapshot_viewSend_disabledFileSend() {
        processor.state = ViewSendItemState(
            sendView: .fixture(
                type: .file,
                file: .fixture(fileName: "photo_123.jpg", sizeName: "3.25 MB"),
                disabled: true,
            ),
            shareURL: URL(string: "send.bitwarden.com/39ngaol3"),
        )
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The view send view for a disabled text send whose type is restricted by policy renders
    /// correctly, with the send-link section and edit FAB hidden.
    @MainActor
    func disabletest_snapshot_viewSend_disabledTextSend_typeRestricted() {
        var state = ViewSendItemState(
            sendView: .fixture(name: "My text send", text: .fixture(text: "Some text to send"), disabled: true),
            shareURL: URL(string: "send.bitwarden.com/39ngaol3"),
        )
        state.sendPolicyOptions = SendPolicyOptions(enforcedSendType: .file)
        processor.state = state
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The view send view for a disabled text send whose type isn't restricted by policy renders
    /// correctly, with the "Make a copy" action shown in the banner.
    @MainActor
    func disabletest_snapshot_viewSend_disabledTextSend_makeACopy() {
        processor.state = ViewSendItemState(
            sendView: .fixture(name: "My text send", text: .fixture(text: "Some text to send"), disabled: true),
            shareURL: URL(string: "send.bitwarden.com/39ngaol3"),
        )
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }
}
