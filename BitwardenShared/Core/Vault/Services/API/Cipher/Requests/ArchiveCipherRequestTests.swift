import XCTest

@testable import BitwardenShared

class ArchiveCipherRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `body` returns nil.
    func test_body() throws {
        let subject = try ArchiveCipherRequest(id: "1")
        XCTAssertNil(subject.body)
    }

    /// `method` returns the method of the request.
    func test_method() throws {
        let subject = try ArchiveCipherRequest(id: "1")
        XCTAssertEqual(subject.method, .put)
    }

    /// `path` returns the path of the request.
    func test_path() throws {
        let subject = try ArchiveCipherRequest(id: "1")
        XCTAssertEqual(subject.path, "/ciphers/1/archive/")
    }
}
