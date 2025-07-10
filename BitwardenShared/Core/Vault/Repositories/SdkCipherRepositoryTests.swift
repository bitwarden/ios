import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - SdkCipherRepositoryTests

class SdkCipherRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var cipherService: MockCipherService!
    var errorReporter: MockErrorReporter!
    var subject: SdkCipherRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        errorReporter = MockErrorReporter()
        subject = SdkCipherRepository(cipherService: cipherService, errorReporter: errorReporter)
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `get(id:)` fetches the cipher by its ID.
    func test_get() async throws {
        cipherService.fetchCipherResult = .success(.fixture(id: "1"))
        let cipher = try await subject.get(id: "1")
        XCTAssertNotNil(cipher)
        XCTAssertEqual(cipher?.id, "1")
    }

    /// `has(id:)` returns whether there is a cipher with the ID.
    func test_has() async throws {
        cipherService.fetchCipherByIdResult = { cipherId in
            .success(cipherId == "1" ? .fixture(id: "1") : nil)
        }

        let hasCipher1 = try await subject.has(id: "1")
        XCTAssertTrue(hasCipher1)

        let hasCipher2 = try await subject.has(id: "2")
        XCTAssertFalse(hasCipher2)
    }

    /// `has(id:)` returns `false` if fetching the cipher throws.
    func test_has_falseOnThrow() async throws {
        cipherService.fetchCipherResult = .failure(BitwardenTestError.example)

        let hasCipher = try await subject.has(id: "1")
        XCTAssertFalse(hasCipher)
    }

    /// `list()` returns a list of ciphers.
    func test_list() async throws {
        cipherService.fetchAllCiphersResult = .success([.fixture(id: "1"), .fixture(id: "2")])

        let ciphers = try await subject.list()
        XCTAssertEqual(ciphers.map(\.id), ["1", "2"])
    }

    /// `remove(id:)` deletes the cipher from local storage by ID.
    func test_remove() async throws {
        try await subject.remove(id: "1")
        XCTAssertEqual(cipherService.deleteCipherWithLocalStorageId, "1")
    }

    /// `set(id:value:)` updates the cipher with local storage.
    func test_set() async throws {
        try await subject.set(id: "1", value: .fixture(id: "1"))
        XCTAssertEqual(cipherService.updateCipherWithLocalStorageCiphers.count, 1)
        XCTAssertEqual(cipherService.updateCipherWithLocalStorageCiphers[safeIndex: 0]?.id, "1")
    }

    /// `set(id:value:)` doesn't update the cipher with local storage when the ID being passed
    /// doesn't match the ID of the `value` and logs the error.
    func test_set_nonMatchingIds() async throws {
        try await subject.set(id: "1", value: .fixture(id: "5"))
        XCTAssertTrue(cipherService.updateCipherWithLocalStorageCiphers.isEmpty)
        let nsError = try XCTUnwrap(errorReporter.errors[safeIndex: 0] as? NSError)
        XCTAssertEqual(
            nsError.userInfo["ErrorMessage"] as? String,
            "CipherRepository: Trying to update a cipher with mismatch IDs"
        )
    }
}
