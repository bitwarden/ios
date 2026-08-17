// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import Foundation
import SnapshotTesting
import UIKit
import XCTest

@testable import BitwardenShared

class AttachmentPreviewViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AttachmentPreviewState, AttachmentPreviewAction, AttachmentPreviewEffect>!
    var subject: AttachmentPreviewView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: .fixture())
        let store = Store(processor: processor)

        subject = AttachmentPreviewView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Previews

    /// The image content renders correctly.
    @MainActor
    func disabletest_snapshot_attachmentPreview_image() {
        processor.state = .fixture(content: .image(UIImage(systemName: "photo")?.pngData() ?? Data()))
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
            ],
        )
    }

    /// The unsupported file type content renders correctly.
    @MainActor
    func disabletest_snapshot_attachmentPreview_unsupportedFileType() {
        processor.state = .fixture(content: .unsupportedFileType(fileExtension: "PDF"))
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .defaultPortraitAX5,
            ],
        )
    }

    /// The file error content renders correctly.
    @MainActor
    func disabletest_snapshot_attachmentPreview_fileError() {
        processor.state = .fixture(content: .fileError)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
            ],
        )
    }

    /// A long file name is truncated in the navigation bar.
    @MainActor
    func disabletest_snapshot_attachmentPreview_longFileName() {
        let fileName = String(repeating: "selfieWithACat", count: 5) + ".png"
        processor.state = .fixture(fileName: fileName)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait],
        )
    }
}

// MARK: - AttachmentPreviewState Fixture

private extension AttachmentPreviewState {
    static func fixture(
        attachment: AttachmentView = .fixture(fileName: "photo.png"),
        content: AttachmentPreviewContent = .fileError,
        fileName: String = "photo.png",
        temporaryUrl: URL = URL(fileURLWithPath: "/tmp/photo.png"),
    ) -> AttachmentPreviewState {
        AttachmentPreviewState(
            attachment: attachment,
            content: content,
            fileName: fileName,
            temporaryUrl: temporaryUrl,
        )
    }
}
