import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class AddCipherWithCollectionsRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: AddCipherWithCollectionsRequest!

    override func setUp() {
        super.setUp()

        subject = AddCipherWithCollectionsRequest(
            cipher: .fixture(
                collectionIds: ["1", "2", "3"],
                revisionDate: Date(year: 2023, month: 10, day: 31)
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns the JSON encoded cipher.
    func test_body() throws {
        assertInlineSnapshot(of: subject.body as CipherCreateRequestModel?, as: .json) {
            """
            {
              "cipher" : {
                "favorite" : false,
                "lastKnownRevisionDate" : 720403200,
                "name" : "Bitwarden",
                "reprompt" : 0,
                "type" : 1
              },
              "collectionIds" : [
                "1",
                "2",
                "3"
              ]
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
        XCTAssertEqual(subject.path, "/ciphers/create")
    }
}
