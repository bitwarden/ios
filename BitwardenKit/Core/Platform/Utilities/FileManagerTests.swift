import XCTest

@testable import BitwardenKit

class FileManagerTests: BitwardenTestCase {
    // MARK: Properties

    var tempFileURL: URL!
    var subject: FileManager!

    // MARK: Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        let directoryURL = try XCTUnwrap(URL(fileURLWithPath: NSTemporaryDirectory()))
        tempFileURL = directoryURL.appendingPathComponent(UUID().uuidString)

        subject = FileManager.default
    }

    override func tearDown() async throws {
        try await super.tearDown()

        try? subject.removeItem(at: tempFileURL)

        subject = nil
    }

    // MARK: Tests

    /// `append(_:to:)` appends the data to the file at the URL.
    func test_append() throws {
        try Data().write(to: tempFileURL)

        for lineNumber in 1 ... 3 {
            try subject.append(Data("line\(lineNumber)\n".utf8), to: tempFileURL)
        }

        let fileContents = try String(contentsOf: tempFileURL)
        XCTAssertEqual(
            fileContents,
            """
            line1
            line2
            line3

            """,
        )
    }

    /// `createDirectory(at:withIntermediateDirectories:)` creates the directory at the specified URL.
    func test_createDirectory() throws {
        let directoryURL = try XCTUnwrap(URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try subject.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        var isDirectory: ObjCBool = false
        let directoryExists = subject.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory)

        XCTAssertTrue(directoryExists)
        XCTAssertTrue(isDirectory.boolValue)

        try subject.removeItem(at: directoryURL)
    }

    /// `setIsExcludedFromBackup()` sets whether the file is excluded from backups.
    func test_setIsExcludedFromBackup() throws {
        try Data().write(to: tempFileURL)

        try subject.setIsExcludedFromBackup(true, to: tempFileURL)
        var values = try tempFileURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true)

        try subject.setIsExcludedFromBackup(false, to: tempFileURL)
        values = try tempFileURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, false)
    }

    /// `write(_:to:)` writes the data to the file at the URL.
    func test_write() throws {
        try subject.write(Data("write1".utf8), to: tempFileURL)
        try subject.write(Data("write2".utf8), to: tempFileURL)

        let fileContents = try String(contentsOf: tempFileURL)
        XCTAssertEqual(fileContents, "write2")
    }
}
