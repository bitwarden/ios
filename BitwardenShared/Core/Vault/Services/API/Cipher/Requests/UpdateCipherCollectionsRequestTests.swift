import InlineSnapshotTesting
import Testing

@testable import BitwardenShared

struct UpdateCipherCollectionsRequestTests {
    // MARK: Tests

    @Test("`init(cipher:)` throws when the cipher has no id.")
    func init_missingId() {
        #expect(throws: UpdateCipherCollectionsRequestError.missingCipherId) {
            try UpdateCipherCollectionsRequest(cipher: .fixture(id: nil))
        }
    }

    @Test("`body` returns the JSON-encoded collection IDs.")
    func body() throws {
        let subject = try UpdateCipherCollectionsRequest(
            cipher: .fixture(collectionIds: ["collection-1", "collection-2"], id: "123"),
        )
        assertInlineSnapshot(of: subject.body as CipherCollectionsRequestModel?, as: .json) {
            """
            {
              "collectionIds" : [
                "collection-1",
                "collection-2"
              ]
            }
            """
        }
    }

    @Test("`method` returns PUT.")
    func method() throws {
        let subject = try UpdateCipherCollectionsRequest(cipher: .fixture(id: "123"))
        #expect(subject.method == .put)
    }

    @Test("`path` returns the collections_v2 path for the cipher.")
    func path() throws {
        let subject = try UpdateCipherCollectionsRequest(cipher: .fixture(id: "123"))
        #expect(subject.path == "/ciphers/123/collections_v2")
    }
}
