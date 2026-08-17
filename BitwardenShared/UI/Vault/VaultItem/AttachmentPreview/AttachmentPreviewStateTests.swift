import BitwardenSdk
import Foundation
import Testing

@testable import BitwardenShared

// MARK: - AttachmentPreviewStateTests

struct AttachmentPreviewStateTests {
    // MARK: Tests

    /// `truncatedFileName` leaves short file names unaffected.
    @Test
    func truncatedFileName_shortName() {
        let subject = AttachmentPreviewState(
            attachment: .fixture(fileName: "photo.png"),
            content: .fileError,
            fileName: "photo.png",
            temporaryUrl: URL(fileURLWithPath: "/tmp/photo.png"),
        )
        #expect(subject.truncatedFileName == "photo.png")
    }

    /// `truncatedFileName` middle-truncates a long file name while preserving the extension.
    @Test
    func truncatedFileName_longName() {
        let name = String(repeating: "a", count: 50) + ".pdf"
        let subject = AttachmentPreviewState(
            attachment: .fixture(fileName: name),
            content: .fileError,
            fileName: name,
            temporaryUrl: URL(fileURLWithPath: "/tmp/\(name)"),
        )

        let expected = String(repeating: "a", count: 18) + "…" + String(repeating: "a", count: 17) + ".pdf"
        #expect(subject.truncatedFileName == expected)
        #expect(subject.truncatedFileName.count == 40)
    }

    /// `truncatedFileName` middle-truncates a long file name with no extension.
    @Test
    func truncatedFileName_longName_noExtension() {
        let name = String(repeating: "b", count: 50)
        let subject = AttachmentPreviewState(
            attachment: .fixture(fileName: name),
            content: .fileError,
            fileName: name,
            temporaryUrl: URL(fileURLWithPath: "/tmp/\(name)"),
        )

        let expected = String(repeating: "b", count: 20) + "…" + String(repeating: "b", count: 19)
        #expect(subject.truncatedFileName == expected)
        #expect(subject.truncatedFileName.count == 40)
    }
}
