import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SdkLocalUserDataKeyStateRepositoryTests

class SdkLocalUserDataKeyStateRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var stateService: MockLocalUserDataStateService!
    var subject: SdkLocalUserDataKeyStateRepository!
    let userId = "user-1"

    /// In-memory backing store keyed by userId → [keyId: UserKeyData], shared via closures.
    var storage: [String: [String: UserKeyData]] = [:]

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stateService = MockLocalUserDataStateService()
        subject = SdkLocalUserDataKeyStateRepository(
            stateService: stateService,
            userId: userId,
        )

        stateService.getLocalUserDataKeyStatesClosure = { [weak self] userId in
            self?.storage[userId]
        }

        stateService.setLocalUserDataKeyStateClosure = { [weak self] id, value, userId in
            self?.storage[userId, default: [:]][id] = value
        }

        stateService.removeLocalUserDataKeyStateClosure = { [weak self] id, userId in
            self?.storage[userId]?.removeValue(forKey: id)
        }
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        subject = nil
        storage = [:]
    }

    // MARK: Tests

    /// `set(id:value:)` then `get(id:)` returns the stored value.
    func test_set_thenGet_returnsValue() async throws {
        let state = LocalUserDataKeyState(wrappedKey: "encryptedKey1")
        try await subject.set(id: "k1", value: state)
        let result = try await subject.get(id: "k1")
        XCTAssertEqual(result?.wrappedKey, "encryptedKey1")
    }

    /// `get(id:)` returns nil for an unknown ID.
    func test_get_missingId_returnsNil() async throws {
        let result = try await subject.get(id: "missing")
        XCTAssertNil(result)
    }

    /// `set(id:value:)` overwrites an existing value.
    func test_set_overwritesExisting() async throws {
        try await subject.set(id: "k1", value: LocalUserDataKeyState(wrappedKey: "first"))
        try await subject.set(id: "k1", value: LocalUserDataKeyState(wrappedKey: "second"))
        let result = try await subject.get(id: "k1")
        XCTAssertEqual(result?.wrappedKey, "second")
    }

    /// `has(id:)` returns true after a value is set.
    func test_has_afterSet_returnsTrue() async throws {
        try await subject.set(id: "k1", value: LocalUserDataKeyState(wrappedKey: "key"))
        let result = try await subject.has(id: "k1")
        XCTAssertTrue(result)
    }

    /// `has(id:)` returns false for an unknown ID.
    func test_has_withoutSet_returnsFalse() async throws {
        let result = try await subject.has(id: "missing")
        XCTAssertFalse(result)
    }

    /// `list()` returns all stored values.
    func test_list_returnsAllValues() async throws {
        try await subject.set(id: "k1", value: LocalUserDataKeyState(wrappedKey: "key1"))
        try await subject.set(id: "k2", value: LocalUserDataKeyState(wrappedKey: "key2"))
        let results = try await subject.list()
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(where: { $0.wrappedKey == "key1" }))
        XCTAssertTrue(results.contains(where: { $0.wrappedKey == "key2" }))
    }

    /// `remove(id:)` removes a stored value.
    func test_remove_deletesValue() async throws {
        try await subject.set(id: "k1", value: LocalUserDataKeyState(wrappedKey: "key"))
        try await subject.remove(id: "k1")
        let result = try await subject.get(id: "k1")
        XCTAssertNil(result)
    }

    /// `removeBulk(keys:)` removes multiple stored values.
    func test_removeBulk_deletesValues() async throws {
        try await subject.set(id: "k1", value: LocalUserDataKeyState(wrappedKey: "key1"))
        try await subject.set(id: "k2", value: LocalUserDataKeyState(wrappedKey: "key2"))
        try await subject.set(id: "k3", value: LocalUserDataKeyState(wrappedKey: "key3"))

        stateService.removeBulkLocalUserDataKeyStatesClosure = { [weak self] keys, userId in
            for key in keys {
                self?.storage[userId]?.removeValue(forKey: key)
            }
        }

        try await subject.removeBulk(keys: ["k1", "k2"])
        let removed1 = try await subject.get(id: "k1")
        let removed2 = try await subject.get(id: "k2")
        let kept3 = try await subject.get(id: "k3")
        XCTAssertNil(removed1)
        XCTAssertNil(removed2)
        XCTAssertNotNil(kept3)
    }

    /// `removeAll()` clears all stored values.
    func test_removeAll_clearsAll() async throws {
        try await subject.set(id: "k1", value: LocalUserDataKeyState(wrappedKey: "key1"))
        try await subject.set(id: "k2", value: LocalUserDataKeyState(wrappedKey: "key2"))

        stateService.removeAllLocalUserDataKeyStatesClosure = { [weak self] userId in
            self?.storage[userId] = nil
        }

        try await subject.removeAll()
        let results = try await subject.list()
        let userDataKeyStates = try await stateService.getLocalUserDataKeyStates(userId: userId)
        XCTAssertTrue(results.isEmpty)
        XCTAssertNil(userDataKeyStates)
    }

    /// `setBulk(values:)` stores multiple values at once.
    func test_setBulk_storesAllValues() async throws {
        stateService.setBulkLocalUserDataKeyStatesClosure = { [weak self] values, userId in
            for (id, value) in values {
                self?.storage[userId, default: [:]][id] = value
            }
        }
        try await subject.setBulk(values: [
            "k1": LocalUserDataKeyState(wrappedKey: "key1"),
            "k2": LocalUserDataKeyState(wrappedKey: "key2"),
        ])
        let k1Value = try await subject.get(id: "k1")
        let k2Value = try await subject.get(id: "k2")
        XCTAssertEqual(k1Value?.wrappedKey, "key1")
        XCTAssertEqual(k2Value?.wrappedKey, "key2")
    }

    /// Values are isolated per user — a different user ID does not see this user's data.
    func test_userIsolation() async throws {
        try await subject.set(id: "k1", value: LocalUserDataKeyState(wrappedKey: "key"))
        let other = SdkLocalUserDataKeyStateRepository(
            stateService: stateService,
            userId: "user-2",
        )
        let result = try await other.get(id: "k1")
        XCTAssertNil(result)
    }
}
