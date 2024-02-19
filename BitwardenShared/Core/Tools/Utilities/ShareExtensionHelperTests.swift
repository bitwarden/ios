import UniformTypeIdentifiers
import XCTest

@testable import BitwardenShared

// MARK: - ShareExtensionHelperTests

class ShareExtensionHelperTests: BitwardenTestCase {
    // MARK: Properties

    var subject: ShareExtensionHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = ShareExtensionHelper(timeProvider: MockTimeProvider(.mockTime(Date(year: 2024, month: 2, day: 1))))
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `processInputItems(_:)` processes the input items for the extension setup and returns a
    /// `.text` type.
    func test_processInputItems_text() async {
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: "text value" as NSString,
                typeIdentifier: UTType.plainText.identifier
            ),
        ]

        let content = await subject.processInputItems([extensionItem])

        XCTAssertEqual(content, .text("text value"))
    }

    /// `processInputItems(_:)` processes the input items for the extension setup and returns a
    /// `.file` type.
    func test_processInputItems_file() async throws {
        let data = Data("example".utf8)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("example.txt")

        // Write to a temporary file
        try data.write(to: url)

        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: url as NSURL,
                typeIdentifier: UTType.data.identifier
            ),
        ]

        let content = await subject.processInputItems([extensionItem])

        XCTAssertEqual(content, .file(fileName: "example.txt", fileData: data))

        // Clean up the temporary file
        try FileManager.default.removeItem(at: url)
    }

    /// `processInputItems(_:)` processes the input image for the extension setup and returns a
    /// `.file` type.
    func test_processInputItems_image() async throws {
        let data = UIImage(systemName: "star.fill")

        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: data! as UIImage,
                typeIdentifier: UTType.image.identifier
            ),
        ]

        let content = await subject.processInputItems([extensionItem])

        XCTAssertEqual(content, .file(fileName: "image_20240201000000.png", fileData: data!.pngData()!))
    }

    /// `processInputItems(_:)` processes the input items for content but does not return anything.
    func test_processInputItems_notSupportedType() async {
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: URL.example as NSURL,
                typeIdentifier: UTType.url.identifier
            ),
        ]

        let content = await subject.processInputItems([extensionItem])

        XCTAssertNil(content)
    }
}
