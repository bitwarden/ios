import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - PasskeyCredentialStoreTests

/// Tests for `DefaultPasskeyCredentialStore`.
///
class PasskeyCredentialStoreTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultPasskeyCredentialStore!
    var userDefaults: UserDefaults!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "PasskeyCredentialStoreTests")
        userDefaults.removePersistentDomain(forName: "PasskeyCredentialStoreTests")
        subject = DefaultPasskeyCredentialStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()
        userDefaults.removePersistentDomain(forName: "PasskeyCredentialStoreTests")
        subject = nil
        userDefaults = nil
    }

    // MARK: Tests

    /// `fetchAll()` returns an empty list when nothing has been saved yet.
    func test_fetchAll_isInitiallyEmpty() throws {
        XCTAssertEqual(try subject.fetchAll(), [])
    }

    /// `save(_:)` persists a credential so it can be read back via `fetchAll()`.
    func test_save_persistsCredential() throws {
        try subject.save(.fixture())
        XCTAssertEqual(try subject.fetchAll(), [.fixture()])
    }

    /// `save(_:)` appends to the existing list rather than overwriting it, preserving order.
    func test_save_appendsMultipleCredentials() throws {
        let first = StoredPasskeyCredential.fixture(rpId: "bitwarden.com", credentialId: Data([0x01]))
        let second = StoredPasskeyCredential.fixture(rpId: "example.com", credentialId: Data([0x02]))

        try subject.save(first)
        try subject.save(second)

        XCTAssertEqual(try subject.fetchAll(), [first, second])
    }

    /// `save(_:)` keeps credentials with the same relying party ID but different credential IDs
    /// as separate entries, rather than overwriting the most recent one per relying party.
    func test_save_sameRpIdDifferentCredentialId_bothPersisted() throws {
        let first = StoredPasskeyCredential.fixture(rpId: "bitwarden.com", credentialId: Data([0x01]))
        let second = StoredPasskeyCredential.fixture(rpId: "bitwarden.com", credentialId: Data([0x02]))

        try subject.save(first)
        try subject.save(second)

        XCTAssertEqual(try subject.fetchAll(), [first, second])
    }

    /// `fetchAll()` throws rather than crashing when the stored data can't be decoded.
    func test_fetchAll_malformedStoredData_throwsDecodingError() {
        userDefaults.set(Data("not json".utf8), forKey: "TestHarness:StoredPasskeyCredentials")
        XCTAssertThrowsError(try subject.fetchAll())
    }

    /// A credential saved via one store instance is visible to a second store instance backed by
    /// the same `UserDefaults`, proving data survives across app relaunches.
    func test_save_persistsAcrossNewStoreInstance() throws {
        try subject.save(.fixture())

        let secondInstance = DefaultPasskeyCredentialStore(userDefaults: userDefaults)
        XCTAssertEqual(try secondInstance.fetchAll(), [.fixture()])
    }

    /// `delete(id:)` removes only the credential with the matching identifier, leaving the rest.
    func test_delete_removesMatchingCredential() throws {
        let first = StoredPasskeyCredential.fixture(rpId: "bitwarden.com", credentialId: Data([0x01]))
        let second = StoredPasskeyCredential.fixture(rpId: "example.com", credentialId: Data([0x02]))
        try subject.save(first)
        try subject.save(second)

        try subject.delete(id: first.id)

        XCTAssertEqual(try subject.fetchAll(), [second])
    }

    /// `delete(id:)` is a no-op when no stored credential matches the given identifier.
    func test_delete_nonexistentId_isNoOp() throws {
        try subject.save(.fixture())

        try subject.delete(id: "nonexistent")

        XCTAssertEqual(try subject.fetchAll(), [.fixture()])
    }

    /// `deleteAll()` removes every stored credential.
    func test_deleteAll_removesAllCredentials() throws {
        try subject.save(.fixture(rpId: "bitwarden.com", credentialId: Data([0x01])))
        try subject.save(.fixture(rpId: "example.com", credentialId: Data([0x02])))

        try subject.deleteAll()

        XCTAssertEqual(try subject.fetchAll(), [])
    }

    /// `deleteAll()` is a no-op when there are no stored credentials.
    func test_deleteAll_whenAlreadyEmpty_isNoOp() throws {
        try subject.deleteAll()

        XCTAssertEqual(try subject.fetchAll(), [])
    }

    /// A credential deleted via one store instance is also gone for a second store instance
    /// backed by the same `UserDefaults`.
    func test_delete_persistsAcrossNewStoreInstance() throws {
        try subject.save(.fixture())

        try subject.delete(id: StoredPasskeyCredential.fixture().id)

        let secondInstance = DefaultPasskeyCredentialStore(userDefaults: userDefaults)
        XCTAssertEqual(try secondInstance.fetchAll(), [])
    }
}
