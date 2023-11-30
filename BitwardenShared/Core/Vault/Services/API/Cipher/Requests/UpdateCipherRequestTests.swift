import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class UpdateCipherRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: UpdateCipherRequest?

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `init` fails if the cipher has no id.
    func test_init_fail_nil() throws {
        subject = UpdateCipherRequest(cipher: .fixture(id: nil, revisionDate: Date(year: 2023, month: 10, day: 31)))
        XCTAssertNil(subject)
    }

    /// `init` fails if the cipher has an empty id.
    func test_init_fail_empty() throws {
        subject = UpdateCipherRequest(cipher: .fixture(id: "", revisionDate: Date(year: 2023, month: 10, day: 31)))
        XCTAssertNil(subject)
    }

    /// `body` returns the JSON encoded cipher.
    func test_body() throws {
        subject = UpdateCipherRequest(cipher: .fixture(id: "123", revisionDate: Date(year: 2023, month: 10, day: 31)))
        XCTAssertNotNil(subject)
        guard let subject else { return }
        assertInlineSnapshot(of: subject.body as CipherRequestModel?, as: .json) {
            """
            {
              "favorite" : false,
              "lastKnownRevisionDate" : 720403200,
              "name" : "Bitwarden",
              "reprompt" : 0,
              "type" : 1
            }
            """
        }
    }

    /// `method` returns the method of the request.
    func test_method() {
        subject = UpdateCipherRequest(cipher: .fixture(id: "123", revisionDate: Date(year: 2023, month: 10, day: 31)))
        XCTAssertEqual(subject?.method, .put)
    }

    /// `path` returns the path of the request.
    func test_path() {
        subject = UpdateCipherRequest(cipher: .fixture(id: "123", revisionDate: Date(year: 2023, month: 10, day: 31)))
        XCTAssertEqual(subject?.path, "/ciphers/123")
    }
}
