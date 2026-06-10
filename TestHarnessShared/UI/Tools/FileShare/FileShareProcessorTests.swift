import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - FileShareProcessorTests

/// Tests for `FileShareProcessor`.
///
@available(iOS 16.0, *)
class FileShareProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var subject: FileShareProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        subject = FileShareProcessor(coordinator: coordinator.asAnyCoordinator())
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Initial State Tests

    /// Initial state has the expected default text content and no shareable URLs or image data.
    @MainActor
    func test_initialState_defaults() {
        XCTAssertEqual(subject.state.textContent, "Sample text to share via Bitwarden Send.")
        XCTAssertNil(subject.state.shareableFileURL)
        XCTAssertNil(subject.state.shareableImageData)
        XCTAssertEqual(subject.state.title, Localizations.fileShare)
    }

    // MARK: Action Tests

    /// `receive(.textContentChanged)` updates the text content in state.
    @MainActor
    func test_receive_textContentChanged() {
        subject.receive(.textContentChanged("Hello, Bitwarden!"))
        XCTAssertEqual(subject.state.textContent, "Hello, Bitwarden!")
    }

    /// `receive(.textContentChanged)` with an empty string clears the field.
    @MainActor
    func test_receive_textContentChanged_emptyStringClearsField() {
        subject.receive(.textContentChanged("Some text"))
        subject.receive(.textContentChanged(""))
        XCTAssertEqual(subject.state.textContent, "")
    }

    /// `receive(.textContentChanged)` overwrites a previously set value.
    @MainActor
    func test_receive_textContentChanged_overwritesPreviousValue() {
        subject.receive(.textContentChanged("First value"))
        subject.receive(.textContentChanged("Second value"))
        XCTAssertEqual(subject.state.textContent, "Second value")
    }

    // MARK: Effect Tests

    /// `perform(.viewAppeared)` writes the sample PDF and sets `shareableFileURL`.
    @MainActor
    func test_perform_viewAppeared_writesFileAndSetsURL() async {
        await subject.perform(.viewAppeared)

        let fileURL = subject.state.shareableFileURL
        XCTAssertNotNil(fileURL)

        if let fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
            XCTAssertEqual(fileURL.lastPathComponent, FileShareState.sampleFileName)

            let writtenData = try? Data(contentsOf: fileURL)
            XCTAssertEqual(writtenData, FileShareState.sampleFileData)
        }
    }

    /// `perform(.viewAppeared)` sets the file URL to the temporary directory.
    @MainActor
    func test_perform_viewAppeared_fileURLIsInTemporaryDirectory() async {
        await subject.perform(.viewAppeared)

        let tempDir = FileManager.default.temporaryDirectory
        XCTAssertEqual(subject.state.shareableFileURL?.deletingLastPathComponent(), tempDir)
    }

    /// `perform(.viewAppeared)` generates PNG data and sets `shareableImageData`.
    @MainActor
    func test_perform_viewAppeared_setsShareableImageData() async {
        await subject.perform(.viewAppeared)

        XCTAssertNotNil(subject.state.shareableImageData)
    }
}
