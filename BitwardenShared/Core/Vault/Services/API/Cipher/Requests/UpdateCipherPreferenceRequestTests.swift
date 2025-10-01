import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class UpdateCipherPreferenceRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: UpdateCipherPreferenceRequest?

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `init` fails if the cipher has no id.
    func test_init_fail_nil() throws {
        XCTAssertThrowsError(
            try UpdateCipherPreferenceRequest(
                cipher: .fixture(
                    id: nil,
                    revisionDate: Date(year: 2023, month: 10, day: 31),
                ),
            ),
        ) { error in
            XCTAssertEqual(error as? CipherAPIServiceError, .updateMissingId)
        }
    }

    /// `init` fails if the cipher has an empty id.
    func test_init_fail_empty() throws {
        XCTAssertThrowsError(
            try UpdateCipherPreferenceRequest(
                cipher: .fixture(id: "", revisionDate: Date(year: 2023, month: 10, day: 31)),
            ),
        ) { error in
            XCTAssertEqual(error as? CipherAPIServiceError, .updateMissingId)
        }
    }

    /// `body` returns the JSON encoded cipher.
    func test_body() throws {
        subject = try XCTUnwrap(UpdateCipherPreferenceRequest(
            cipher: .fixture(
                folderId: "folderId",
                id: "123",
                revisionDate: Date(year: 2023, month: 10, day: 31),
            ),
        ))
        assertInlineSnapshot(of: subject?.body as UpdateCipherPreferenceRequestModel?, as: .json) {
            """
            {
              "favorite" : false,
              "folderId" : "folderId"
            }
            """
        }
    }

    /// `method` returns the method of the request.
    func test_method() throws {
        subject = try UpdateCipherPreferenceRequest(
            cipher: .fixture(
                id: "123",
                revisionDate: Date(year: 2023, month: 10, day: 31),
            ),
        )
        XCTAssertEqual(subject?.method, .put)
    }

    /// `path` returns the path of the request.
    func test_path() throws {
        subject = try UpdateCipherPreferenceRequest(
            cipher: .fixture(
                id: "123",
                revisionDate: Date(year: 2023, month: 10, day: 31),
            ),
        )
        XCTAssertEqual(subject?.path, "/ciphers/123/partial")
    }
}
