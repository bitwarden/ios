import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - ImportCiphersRequestTests

class ImportCiphersRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(ciphers:folders:folderRelationships:)` initializes the request successfully.
    func test_init() throws {
        let subject = try ImportCiphersRequest(
            ciphers: [.fixture(name: "cipherTest")],
            folders: [.fixture(name: "folderTest")],
            folderRelationships: [(1, 1)],
        )
        XCTAssertEqual(subject.body?.ciphers[0].name, "cipherTest")
        XCTAssertEqual(subject.body?.folders[0].name, "folderTest")
        XCTAssertEqual(subject.body?.folderRelationships[0].key, 1)
        XCTAssertEqual(subject.body?.folderRelationships[0].value, 1)
    }

    /// `init(ciphers:folders:folderRelationships:)` initializes the request successfully.
    func test_init_throws() throws {
        XCTAssertThrowsError(_ = try ImportCiphersRequest(
            ciphers: [],
        ))
    }

    /// `path` returns the correct path.
    func test_path() throws {
        let subject = try ImportCiphersRequest(ciphers: [.fixture()])
        XCTAssertEqual(subject.path, "/ciphers/import")
    }

    /// `method` is `.put`.
    func test_method() throws {
        let subject = try ImportCiphersRequest(ciphers: [.fixture()])
        XCTAssertEqual(subject.method, .post)
    }
}
