import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class BulkShareCiphersRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: BulkShareCiphersRequest!

    override func setUp() async throws {
        try await super.setUp()

        subject = try BulkShareCiphersRequest(
            ciphers: [
                .fixture(
                    collectionIds: ["1", "2"],
                    id: "123",
                    revisionDate: Date(year: 2023, month: 10, day: 31),
                ),
                .fixture(
                    collectionIds: ["1", "2"],
                    id: "456",
                    revisionDate: Date(year: 2023, month: 10, day: 31),
                ),
            ],
            collectionIds: ["1", "2"],
            encryptedFor: "user-1",
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns the JSON encoded bulk share request.
    func test_body() throws {
        assertInlineSnapshot(of: subject.body as BulkShareCiphersRequestModel?, as: .json) {
            """
            {
              "ciphers" : [
                {
                  "encryptedFor" : "user-1",
                  "favorite" : false,
                  "id" : "123",
                  "lastKnownRevisionDate" : 720403200,
                  "name" : "Bitwarden",
                  "reprompt" : 0,
                  "type" : 1
                },
                {
                  "encryptedFor" : "user-1",
                  "favorite" : false,
                  "id" : "456",
                  "lastKnownRevisionDate" : 720403200,
                  "name" : "Bitwarden",
                  "reprompt" : 0,
                  "type" : 1
                }
              ],
              "collectionIds" : [
                "1",
                "2"
              ]
            }
            """
        }
    }

    /// `init` throws an error when a cipher is missing an ID.
    func test_init_missingCipherId() {
        XCTAssertThrowsError(
            try BulkShareCiphersRequest(
                ciphers: [
                    .fixture(id: "123"),
                    .fixture(id: nil),
                ],
                collectionIds: ["1"],
                encryptedFor: "user-1",
            ),
        ) { error in
            XCTAssertEqual(error as? BulkShareCiphersRequestError, .missingCipherId)
        }
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .put)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/ciphers/share")
    }
}
