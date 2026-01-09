import BitwardenKitMocks
import BitwardenSdk
import CoreData
import XCTest

@testable import BitwardenShared

class CipherDataStoreTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DataStore!

    let ciphers = [
        Cipher.fixture(id: "1", name: "CIPHER1"),
        Cipher.fixture(id: "2", name: "CIPHER2"),
        Cipher.fixture(id: "3", name: "CIPHER3"),
    ]

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `cipherCount(userId:)` returns the count of ciphers in the data store.
    func test_cipherCount() async throws {
        var count = try await subject.cipherCount(userId: "1")
        XCTAssertEqual(count, 0)

        try await insertCiphers(ciphers, userId: "1")
        try await insertCiphers(ciphers, userId: "2")

        count = try await subject.cipherCount(userId: "1")
        XCTAssertEqual(count, 3)
    }

    /// `cipherPublisher(userId:)` returns a publisher for a user's cipher objects.
    func test_cipherPublisher() async throws {
        var iterator = subject.cipherPublisher(userId: "1").valuesWithTimeout().makeAsyncIterator()

        let firstValue = try await iterator.next()
        XCTAssertEqual(firstValue, [])

        try await subject.replaceCiphers(ciphers, userId: "1")

        let secondValue = try await iterator.next()
        XCTAssertEqual(secondValue, ciphers)
    }

    /// `cipherChangesPublisher(userId:)` emits inserted ciphers for the user.
    func test_cipherChangesPublisher_insert() async throws {
        var publishedChanges = [CipherChange]()
        let publisher = subject.cipherChangesPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { change in
                    publishedChanges.append(change)
                },
            )
        defer { publisher.cancel() }

        let cipher = Cipher.fixture(id: "1", name: "CIPHER1")
        try await subject.upsertCipher(cipher, userId: "1")

        waitFor { publishedChanges.count == 1 }
        guard case let .upserted(insertedCipher) = publishedChanges[0] else {
            XCTFail("Expected upserted change")
            return
        }
        XCTAssertEqual(insertedCipher.id, cipher.id)
        XCTAssertEqual(insertedCipher.name, cipher.name)
    }

    /// `cipherChangesPublisher(userId:)` emits updated ciphers for the user.
    func test_cipherChangesPublisher_update() async throws {
        // Insert initial cipher
        try await insertCiphers([ciphers[0]], userId: "1")

        var publishedChanges = [CipherChange]()
        let publisher = subject.cipherChangesPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { change in
                    publishedChanges.append(change)
                },
            )
        defer { publisher.cancel() }

        let updatedCipher = Cipher.fixture(id: "1", name: "UPDATED CIPHER1")
        try await subject.upsertCipher(updatedCipher, userId: "1")

        waitFor { publishedChanges.count == 1 }
        guard case let .upserted(updated) = publishedChanges[0] else {
            XCTFail("Expected upserted change")
            return
        }
        XCTAssertEqual(updated.id, updatedCipher.id)
        XCTAssertEqual(updated.name, updatedCipher.name)
    }

    /// `cipherChangesPublisher(userId:)` emits deleted cipher IDs for the user.
    func test_cipherChangesPublisher_delete() async throws {
        // Insert initial ciphers
        try await insertCiphers(ciphers, userId: "1")

        var publishedChanges = [CipherChange]()
        let publisher = subject.cipherChangesPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { change in
                    publishedChanges.append(change)
                },
            )
        defer { publisher.cancel() }

        try await subject.deleteCipher(id: "2", userId: "1")

        waitFor { publishedChanges.count == 1 }
        guard case let .deleted(deletedCipher) = publishedChanges[0] else {
            XCTFail("Expected deleted change")
            return
        }
        XCTAssertEqual(deletedCipher.id, "2")
    }

    /// `cipherChangesPublisher(userId:)` emits replaced changes for replace operations.
    func test_cipherChangesPublisher_replace() async throws {
        var publishedChanges = [CipherChange]()
        let publisher = subject.cipherChangesPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { change in
                    publishedChanges.append(change)
                },
            )
        defer { publisher.cancel() }

        try await subject.replaceCiphers(ciphers, userId: "1")

        waitFor { publishedChanges.count == 1 }
        guard case .replaced = publishedChanges[0] else {
            XCTFail("Expected replaced change")
            return
        }
    }

    /// `cipherChangesPublisher(userId:)` does not emit changes for other users.
    func test_cipherChangesPublisher_doesNotEmitForOtherUsers() async throws {
        var publishedChanges = [CipherChange]()
        let publisher = subject.cipherChangesPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { change in
                    publishedChanges.append(change)
                },
            )
        defer { publisher.cancel() }

        // Insert cipher for a different user
        let cipher = Cipher.fixture(id: "1", name: "CIPHER1")
        try await subject.upsertCipher(cipher, userId: "2")

        // Wait a bit to ensure no changes are emitted
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        XCTAssertTrue(publishedChanges.isEmpty)
    }

    /// `deleteAllCiphers(user:)` removes all objects for the user.
    func test_deleteAllCiphers() async throws {
        try await insertCiphers(ciphers, userId: "1")
        try await insertCiphers(ciphers, userId: "2")

        try await subject.deleteAllCiphers(userId: "1")

        try XCTAssertTrue(fetchCiphers(userId: "1").isEmpty)
        try XCTAssertEqual(fetchCiphers(userId: "2").count, 3)
    }

    /// `deleteCipher(id:userId:)` removes the cipher with the given ID for the user.
    func test_deleteCipher() async throws {
        try await insertCiphers(ciphers, userId: "1")

        try await subject.deleteCipher(id: "2", userId: "1")

        try XCTAssertEqual(
            fetchCiphers(userId: "1"),
            ciphers.filter { $0.id != "2" },
        )
    }

    /// `fetchCipher(withId:)` returns the specified cipher if it exists and `nil` otherwise.
    func test_fetchCipher() async throws {
        try await insertCiphers(ciphers, userId: "1")

        let cipher1 = try await subject.fetchCipher(withId: "1", userId: "1")
        XCTAssertEqual(cipher1, ciphers.first)

        let cipher42 = try await subject.fetchCipher(withId: "42", userId: "1")
        XCTAssertNil(cipher42)
    }

    /// `replaceCiphers(_:userId)` replaces the list of ciphers for the user.
    func test_replaceCiphers() async throws {
        try await insertCiphers(ciphers, userId: "1")

        let newCiphers = [
            Cipher.fixture(id: "3", name: "CIPHER3"),
            Cipher.fixture(id: "4", name: "CIPHER4"),
            Cipher.fixture(id: "5", name: "CIPHER5"),
        ]
        try await subject.replaceCiphers(newCiphers, userId: "1")

        XCTAssertEqual(try fetchCiphers(userId: "1"), newCiphers)
    }

    /// `upsertCipher(_:userId:)` inserts a cipher for a user.
    func test_upsertCipher_insert() async throws {
        let cipher = Cipher.fixture(id: "1")
        try await subject.upsertCipher(cipher, userId: "1")

        try XCTAssertEqual(fetchCiphers(userId: "1"), [cipher])

        let cipher2 = Cipher.fixture(id: "2")
        try await subject.upsertCipher(cipher2, userId: "1")

        try XCTAssertEqual(fetchCiphers(userId: "1"), [cipher, cipher2])
    }

    /// `upsertCipher(_:userId:)` updates an existing cipher for a user.
    func test_upsertCipher_update() async throws {
        try await insertCiphers(ciphers, userId: "1")

        let updatedCipher = Cipher.fixture(id: "2", name: "UPDATED CIPHER2")
        try await subject.upsertCipher(updatedCipher, userId: "1")

        var expectedCiphers = ciphers
        expectedCiphers[1] = updatedCipher

        try XCTAssertEqual(fetchCiphers(userId: "1"), expectedCiphers)
    }

    // MARK: Test Helpers

    /// A test helper to fetch all cipher's for a user.
    private func fetchCiphers(userId: String) throws -> [Cipher] {
        let fetchRequest = CipherData.fetchByUserIdRequest(userId: userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CipherData.id, ascending: true)]
        return try subject.backgroundContext.fetch(fetchRequest).map(Cipher.init)
    }

    /// A test helper for inserting a list of ciphers for a user.
    private func insertCiphers(_ ciphers: [Cipher], userId: String) async throws {
        try await subject.backgroundContext.performAndSave {
            for cipher in ciphers {
                _ = try CipherData(context: self.subject.backgroundContext, userId: userId, cipher: cipher)
            }
        }
    }
}
