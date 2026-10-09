import BitwardenKit
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - UpdateSendRequestTests

class UpdateSendRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(send:)` with a send id initializes the properties correctly.
    func test_init_send_withId() throws {
        let send = Send.fixture(id: "ID")
        let subject = try UpdateSendRequest(send: send)

        XCTAssertEqual(subject.path, "/sends/ID")
        XCTAssertEqual(subject.method, .put)
        XCTAssertEqual(subject.sendId, "ID")
    }

    /// `init(send:)` includes the send's sealed item data and metadata in the request body.
    func test_init_send_data() throws {
        let send = Send.fixture(data: SendItem(
            encryptionVersion: .v1,
            data: "SEALED",
            metadata: SendItemMetadata(itemId: "CIPHER_ID"),
        ))
        let subject = try UpdateSendRequest(send: send)

        let body = try XCTUnwrap(subject.body?.encode())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let data = try XCTUnwrap(json["data"] as? [String: Any])
        XCTAssertEqual(data["data"] as? String, "SEALED")
        let metadata = try XCTUnwrap(data["metadata"] as? [String: Any])
        XCTAssertEqual(metadata["itemId"] as? String, "CIPHER_ID")
    }

    /// `init(send:)` without a send id throws an error.
    func test_init_send_withoutId() {
        let send = Send.fixture(id: nil)
        XCTAssertThrowsError(try UpdateSendRequest(send: send)) { error in
            XCTAssertEqual(
                error as NSError,
                BitwardenError.dataError("Received a send from the API with a missing ID."),
            )
        }
    }
}
