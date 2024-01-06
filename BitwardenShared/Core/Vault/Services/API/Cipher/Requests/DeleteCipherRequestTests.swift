import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class DeleteCipherRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DeleteCipherRequest?

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `init` fails if the cipher has an empty id.
    func test_init_fail_empty() throws {
        XCTAssertThrowsError(
            try DeleteCipherRequest(id: "")
        ) { error in
            XCTAssertEqual(error as? CipherAPIServiceError, .updateMissingId)
        }
    }

    /// `body` returns nil.
    func test_body() throws {
        subject = try DeleteCipherRequest(id: "123")
        XCTAssertNotNil(subject)
        XCTAssertNil(subject?.body)
    }

    /// `method` returns the method of the request.
    func test_method() throws {
        subject = try DeleteCipherRequest(id: "123")
        XCTAssertEqual(subject?.method, .delete)
    }

    /// `path` returns the path of the request.
    func test_path() throws {
        subject = try DeleteCipherRequest(id: "123")
        XCTAssertEqual(subject?.path, "/ciphers/123")
    }
}
