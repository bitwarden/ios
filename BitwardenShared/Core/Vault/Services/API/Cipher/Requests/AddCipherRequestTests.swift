import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class AddCipherRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: AddCipherRequest!

    override func setUp() {
        super.setUp()

        subject = AddCipherRequest(cipher: .fixture())
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns the JSON encoded cipher.
    func test_body() throws {
        assertInlineSnapshot(of: subject.body as CipherRequestModel?, as: .json) {
            """
            {
              "favorite" : false,
              "name" : "Bitwarden",
              "reprompt" : 0,
              "type" : 1
            }
            """
        }
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/ciphers")
    }
}
