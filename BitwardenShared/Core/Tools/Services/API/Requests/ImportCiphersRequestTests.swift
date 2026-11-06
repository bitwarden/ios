import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - ImportCiphersRequestTests

class ImportCiphersRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(encryptionContexts:folders:folderRelationships:)` initializes the request successfully.
    func test_init() throws {
        let subject = try ImportCiphersRequest(
            encryptionContexts: [
                EncryptionContext(
                    encryptedFor: "user-1",
                    encryptedByKeyId: "key-abc",
                    cipher: .fixture(name: "cipherTest"),
                ),
            ],
            folders: [.fixture(name: "folderTest")],
            folderRelationships: [(1, 1)],
        )
        XCTAssertEqual(subject.body?.ciphers[0].name, "cipherTest")
        XCTAssertEqual(subject.body?.ciphers[0].encryptedFor, "user-1")
        XCTAssertEqual(subject.body?.ciphers[0].encryptedByKeyId, "key-abc")
        XCTAssertEqual(subject.body?.folders[0].name, "folderTest")
        XCTAssertEqual(subject.body?.folderRelationships[0].key, 1)
        XCTAssertEqual(subject.body?.folderRelationships[0].value, 1)
    }

    /// `init(encryptionContexts:folders:folderRelationships:)` throws when the contexts are empty.
    func test_init_throws() throws {
        XCTAssertThrowsError(_ = try ImportCiphersRequest(
            encryptionContexts: [],
        ))
    }

    /// `path` returns the correct path.
    func test_path() throws {
        let subject = try ImportCiphersRequest(
            encryptionContexts: [
                EncryptionContext(encryptedFor: "user-1", cipher: .fixture()),
            ],
        )
        XCTAssertEqual(subject.path, "/ciphers/import")
    }

    /// `method` is `.post`.
    func test_method() throws {
        let subject = try ImportCiphersRequest(
            encryptionContexts: [
                EncryptionContext(encryptedFor: "user-1", cipher: .fixture()),
            ],
        )
        XCTAssertEqual(subject.method, .post)
    }
}
