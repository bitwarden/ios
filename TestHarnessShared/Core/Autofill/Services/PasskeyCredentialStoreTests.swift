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
}

// MARK: - StoredPasskeyCredential+Fixtures

private extension StoredPasskeyCredential {
    static func fixture(
        rpId: String = "bitwarden.com",
        userName: String = "user",
        displayName: String = "User",
        credentialId: Data = Data([0x01, 0x02, 0x03]),
        publicKeyX963: Data = Data(repeating: 0x04, count: 65),
        createdAt: Date = Date(timeIntervalSince1970: 0),
    ) -> StoredPasskeyCredential {
        StoredPasskeyCredential(
            rpId: rpId,
            userName: userName,
            displayName: displayName,
            credentialId: credentialId,
            publicKeyX963: publicKeyX963,
            createdAt: createdAt,
        )
    }
}
