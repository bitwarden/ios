import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - SdkCipherRepositoryTests

class SdkCipherRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var cipherDataStore: MockCipherDataStore!
    var subject: SdkCipherRepository!
    let expectedUserId = "1"

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherDataStore = MockCipherDataStore()
        subject = SdkCipherRepository(
            cipherDataStore: cipherDataStore,
            userId: expectedUserId,
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherDataStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `get(id:)` fetches the cipher by its ID.
    func test_get() async throws {
        cipherDataStore.fetchCipherResult = .fixture(id: "1")
        let cipher = try await subject.get(id: "1")
        XCTAssertNotNil(cipher)
        XCTAssertEqual(cipher?.id, "1")
        XCTAssertEqual(cipherDataStore.fetchCipherUserId, expectedUserId)
    }

    /// `has(id:)` returns whether there is a cipher with the ID.
    func test_has() async throws {
        cipherDataStore.fetchCipherResult = .fixture(id: "1")

        let hasCipher1 = try await subject.has(id: "1")
        XCTAssertTrue(hasCipher1)
        XCTAssertEqual(cipherDataStore.fetchCipherUserId, expectedUserId)

        cipherDataStore.fetchCipherResult = nil

        let hasCipher2 = try await subject.has(id: "2")
        XCTAssertFalse(hasCipher2)
    }

    /// `list()` returns a list of ciphers.
    func test_list() async throws {
        cipherDataStore.fetchAllCiphersResult = .success([.fixture(id: "1"), .fixture(id: "2")])

        let ciphers = try await subject.list()
        XCTAssertEqual(ciphers.map(\.id), ["1", "2"])
        XCTAssertEqual(cipherDataStore.fetchAllCiphersUserId, expectedUserId)
    }

    /// `listIter(batchSize:)` returns an iterator that fetches a page per `next()` call, each
    /// continuing after the ID of the last cipher of the previous page, until a short page.
    func test_listIter_pages() async throws {
        cipherDataStore.fetchCiphersResults = [
            .success([.fixture(id: "1"), .fixture(id: "2")]),
            .success([.fixture(id: "3"), .fixture(id: "4")]),
            .success([.fixture(id: "5")]),
        ]

        let iterator = try subject.listIter(batchSize: 2)
        XCTAssertTrue(cipherDataStore.fetchCiphersCalls.isEmpty)

        let firstPage = try await iterator.next()
        XCTAssertEqual(firstPage?.map(\.id), ["1", "2"])
        let secondPage = try await iterator.next()
        XCTAssertEqual(secondPage?.map(\.id), ["3", "4"])
        let lastPage = try await iterator.next()
        XCTAssertEqual(lastPage?.map(\.id), ["5"])
        let end = try await iterator.next()
        XCTAssertNil(end)

        XCTAssertEqual(cipherDataStore.fetchCiphersCalls.map(\.afterId), [nil, "2", "4"])
        XCTAssertEqual(cipherDataStore.fetchCiphersCalls.map(\.limit), [2, 2, 2])
        XCTAssertEqual(cipherDataStore.fetchCiphersUserId, expectedUserId)
    }

    /// `listIter(batchSize:)` returns an iterator that ends with an empty fetch when the last page
    /// is full.
    func test_listIter_fullLastPage() async throws {
        cipherDataStore.fetchCiphersResults = [
            .success([.fixture(id: "1"), .fixture(id: "2")]),
            .success([]),
        ]

        let iterator = try subject.listIter(batchSize: 2)

        let page = try await iterator.next()
        XCTAssertEqual(page?.map(\.id), ["1", "2"])
        let end = try await iterator.next()
        XCTAssertNil(end)
        let afterEnd = try await iterator.next()
        XCTAssertNil(afterEnd)

        XCTAssertEqual(cipherDataStore.fetchCiphersCalls.map(\.afterId), [nil, "2"])
    }

    /// `listIter(batchSize:)` returns an iterator that ends right away when there are no ciphers.
    func test_listIter_empty() async throws {
        let iterator = try subject.listIter(batchSize: 2)

        let end = try await iterator.next()
        XCTAssertNil(end)
        XCTAssertEqual(cipherDataStore.fetchCiphersCalls.count, 1)
    }

    /// `listIter(batchSize:)` returns an iterator that fetches at least one cipher per page.
    func test_listIter_zeroBatchSize() async throws {
        let iterator = try subject.listIter(batchSize: 0)

        _ = try await iterator.next()
        XCTAssertEqual(cipherDataStore.fetchCiphersCalls.map(\.limit), [1])
    }

    /// `listIter(batchSize:)` returns an iterator that throws the error of the data store.
    func test_listIter_error() async throws {
        cipherDataStore.fetchCiphersResults = [.failure(BitwardenTestError.example)]

        let iterator = try subject.listIter(batchSize: 2)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await iterator.next()
        }
    }

    /// `remove(id:)` deletes the cipher from local storage by ID.
    func test_remove() async throws {
        try await subject.remove(id: "1")
        XCTAssertEqual(cipherDataStore.deleteCipherId, "1")
        XCTAssertEqual(cipherDataStore.deleteCipherUserId, expectedUserId)
    }

    /// `set(id:value:)` updates the cipher with local storage.
    func test_set() async throws {
        try await subject.set(id: "1", value: .fixture(id: "1"))
        XCTAssertEqual(cipherDataStore.upsertCipherValue?.id, "1")
        XCTAssertEqual(cipherDataStore.upsertCipherUserId, expectedUserId)
    }

    /// `set(id:value:)` doesn't update the cipher with local storage when the ID being passed
    /// doesn't match the ID of the `value` and throws an error.
    func test_set_nonMatchingIds() async throws {
        do {
            try await subject.set(id: "1", value: .fixture(id: "5"))
        } catch {
            XCTAssertEqual(
                (error as NSError).userInfo["ErrorMessage"] as? String,
                "CipherRepository: Trying to update a cipher with mismatch IDs",
            )
        }

        XCTAssertNil(cipherDataStore.upsertCipherValue)
    }

    /// `removeAll()` deletes all ciphers for the user ID.
    func test_removeAll() async throws {
        try await subject.removeAll()
        XCTAssertEqual(cipherDataStore.deleteAllCiphersUserId, expectedUserId)
    }

    /// `removeBulk(keys:)` deletes each cipher by ID for the user.
    func test_removeBulk() async throws {
        try await subject.removeBulk(keys: ["1", "2", "3"])
        XCTAssertEqual(cipherDataStore.deleteCipherIds, ["1", "2", "3"])
        XCTAssertEqual(cipherDataStore.deleteCipherUserId, expectedUserId)
    }

    /// `removeBulk(keys:)` with an empty list performs no deletions.
    func test_removeBulk_empty() async throws {
        try await subject.removeBulk(keys: [])
        XCTAssertTrue(cipherDataStore.deleteCipherIds.isEmpty)
    }

    /// `setBulk(values:)` upserts all ciphers whose key matches the cipher's ID.
    func test_setBulk() async throws {
        try await subject.setBulk(values: ["1": .fixture(id: "1"), "2": .fixture(id: "2")])
        XCTAssertEqual(cipherDataStore.upsertCipherValues.compactMap(\.id).sorted(), ["1", "2"])
        XCTAssertEqual(cipherDataStore.upsertCipherUserId, expectedUserId)
    }

    /// `setBulk(values:)` throws when any entry's key doesn't match the cipher's ID.
    func test_setBulk_withMismatch() async throws {
        await assertAsyncThrows {
            try await subject.setBulk(values: ["1": .fixture(id: "1"), "2": .fixture(id: "99")])
        }
        XCTAssertTrue(cipherDataStore.upsertCipherValues.isEmpty)
    }

    /// `setBulk(values:)` throws when all entries have mismatched IDs.
    func test_setBulk_allMismatched() async throws {
        await assertAsyncThrows {
            try await subject.setBulk(values: ["1": .fixture(id: "99")])
        }
        XCTAssertTrue(cipherDataStore.upsertCipherValues.isEmpty)
    }

    /// `setBulk(values:)` with an empty map performs no upserts.
    func test_setBulk_empty() async throws {
        try await subject.setBulk(values: [:])
        XCTAssertTrue(cipherDataStore.upsertCipherValues.isEmpty)
    }
}
