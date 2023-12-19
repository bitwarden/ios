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
            ciphers.filter { $0.id != "2" }
        )
    }

    /// `cipherPublisher(userId:)` returns a publisher for a user's cipher objects.
    func test_cipherPublisher() async throws {
        var publishedValues = [[Cipher]]()
        let publisher = subject.cipherPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { values in
                    publishedValues.append(values)
                }
            )
        defer { publisher.cancel() }

        try await subject.replaceCiphers(ciphers, userId: "1")

        waitFor { publishedValues.count == 2 }
        XCTAssertTrue(publishedValues[0].isEmpty)
        XCTAssertEqual(publishedValues[1], ciphers)
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
