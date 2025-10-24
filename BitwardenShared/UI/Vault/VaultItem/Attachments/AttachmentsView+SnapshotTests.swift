// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AttachmentsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AttachmentsState, AttachmentsAction, AttachmentsEffect>!
    var subject: AttachmentsView!

    var cipherWithAttachments: CipherView {
        .fixture(
            attachments: [
                .fixture(fileName: "selfieWithACat.png", id: "1", sizeName: "10 MB"),
                .fixture(fileName: "selfieWithADog.png", id: "2", sizeName: "11.2 MB"),
                .fixture(fileName: "selfieWithAPotato.png", id: "3", sizeName: "201.2 MB"),
            ],
        )
    }

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AttachmentsState())
        let store = Store(processor: processor)

        subject = AttachmentsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Previews

    /// The empty view renders correctly in dark mode.
    @MainActor
    func disabletest_snapshot_attachments_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ],
        )
    }

    /// The view with a selected attachment renders correctly.
    @MainActor
    func disabletest_snapshot_attachments_selected() {
        processor.state.fileName = "photo.jpg"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ],
        )
    }

    /// The view with several attachments renders correctly in dark mode.
    @MainActor
    func disabletest_snapshot_attachments_several() {
        processor.state.cipher = cipherWithAttachments
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ],
        )
    }
}
