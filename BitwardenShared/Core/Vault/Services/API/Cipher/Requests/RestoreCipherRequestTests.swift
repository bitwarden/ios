import InlineSnapshotTesting
import TestHelpers
import XCTest

@testable import BitwardenShared

class RestoreCipherRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: RestoreCipherRequest?

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `init` fails if the cipher has an empty id.
    func test_init_fail_empty() throws {
        XCTAssertThrowsError(
            try RestoreCipherRequest(id: "")
        ) { error in
            XCTAssertEqual(error as? CipherAPIServiceError, .updateMissingId)
        }
    }

    /// `body` returns nil.
    func test_body() throws {
        subject = try RestoreCipherRequest(id: "123")
        XCTAssertNotNil(subject)
        XCTAssertNil(subject?.body)
    }

    /// `method` returns the method of the request.
    func test_method() throws {
        subject = try RestoreCipherRequest(id: "123")
        XCTAssertEqual(subject?.method, .put)
    }

    /// `path` returns the path of the request.
    func test_path() throws {
        subject = try RestoreCipherRequest(id: "123")
        XCTAssertEqual(subject?.path, "/ciphers/123/restore")
    }
}
