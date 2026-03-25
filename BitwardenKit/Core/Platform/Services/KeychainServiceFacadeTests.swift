import BitwardenKit
import BitwardenKitMocks
import XCTest

// MARK: - KeychainServiceFacadeTests

class KeychainServiceFacadeTests: BitwardenTestCase {
    // MARK: Properties

    var appIDSettingsStore: MockAppIDSettingsStore!
    var keychainService: MockKeychainService!
    var subject: DefaultKeychainServiceFacade!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appIDSettingsStore = MockAppIDSettingsStore()
        appIDSettingsStore.appID = "test-app-ID"
        keychainService = MockKeychainService()
        subject = DefaultKeychainServiceFacade(
            appIDService: AppIDService(appIDSettingsStore: appIDSettingsStore),
            appSecAttrAccessGroup: "test-access-group",
            appSecAttrService: "test-service",
            keychainService: keychainService,
            storageKeyPrefix: "test-prefix",
        )
    }

    override func tearDown() {
        super.tearDown()

        appIDSettingsStore = nil
        keychainService = nil
        subject = nil
    }

    // MARK: Tests - getValue(for:) -> String

    /// `getValue(for:)` returns the stored string when the keychain search succeeds.
    ///
    func test_getValue_string_success() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")
        keychainService.setSearchResultData(string: "stored-value")

        let result = try await subject.getValue(for: item)

        XCTAssertEqual(result, "stored-value")
    }

    /// `getValue(for:)` throws `keyNotFound` when the search returns `nil`.
    ///
    func test_getValue_string_nilResult_throwsKeyNotFound() async {
        let item = MockKeychainItem(unformattedKey: "missing_key")
        keychainService.searchResult = .success(nil)

        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(item)) {
            try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` throws `keyNotFound` when the search returns an empty string.
    ///
    func test_getValue_string_emptyString_throwsKeyNotFound() async {
        let item = MockKeychainItem(unformattedKey: "empty_key")
        keychainService.setSearchResultData(string: "")

        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(item)) {
            try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` rethrows errors from the keychain service.
    ///
    func test_getValue_string_keychainError_rethrows() async {
        let item = MockKeychainItem(unformattedKey: "error_key")
        keychainService.searchResult = .failure(.osStatusError(errSecItemNotFound))

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecItemNotFound)) {
            try await subject.getValue(for: item)
        }
    }

    // MARK: Tests - getValue(for:) -> T: Codable

    /// `getValue(for:)` decodes and returns a `Codable` value when the keychain search succeeds.
    ///
    func test_getValue_codable_success() async throws {
        let item = MockKeychainItem(unformattedKey: "codable_key")
        keychainService.setSearchResultData(string: "42")

        let result: Int = try await subject.getValue(for: item)

        XCTAssertEqual(result, 42)
    }

    /// `getValue(for:)` throws a decoding error when the stored string is not valid JSON for the target type.
    ///
    func test_getValue_codable_invalidJSON_throwsDecodingError() async {
        let item = MockKeychainItem(unformattedKey: "bad_json_key")
        keychainService.setSearchResultData(string: "not-a-number")

        await assertAsyncThrows {
            let _: Int = try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` propagates `keyNotFound` when the underlying string getter throws.
    ///
    func test_getValue_codable_keyNotFound_rethrows() async {
        let item = MockKeychainItem(unformattedKey: "missing_codable_key")
        keychainService.searchResult = .success(nil)

        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(item)) {
            let _: Int = try await subject.getValue(for: item)
        }
    }

    // MARK: Tests - setValue(_:for:)

    /// `setValue(_:for:)` updates the existing item when the update succeeds without calling `add`.
    ///
    func test_setValue_updatesExistingItem() async throws {
        let item = makeItem()
        keychainService.accessControlResult = .success(makeAccessControl())
        keychainService.updateResult = .success(())

        try await subject.setValue("new-value", for: item)

        XCTAssertNotNil(keychainService.updateQuery)
        XCTAssertTrue(keychainService.addCalls.isEmpty)
        let storedData = (keychainService.updateAttributes as? [String: Any])?[kSecValueData as String] as? Data
        XCTAssertEqual(storedData, Data("new-value".utf8))
    }

    /// `setValue(_:for:)` falls through to `add` when the update returns `errSecItemNotFound`.
    ///
    func test_setValue_addsNewItem_whenNotFound() async throws {
        let item = makeItem()
        keychainService.accessControlResult = .success(makeAccessControl())
        keychainService.updateResult = .failure(KeychainServiceError.osStatusError(errSecItemNotFound))
        keychainService.addResult = .success(())

        try await subject.setValue("new-value", for: item)

        XCTAssertEqual(keychainService.addCalls.count, 1)
        let storedData = (keychainService.addCalls.first as? [String: Any])?[kSecValueData as String] as? Data
        XCTAssertEqual(storedData, Data("new-value".utf8))
    }

    /// `setValue(_:for:)` passes the item's `protection` and `accessControlFlags` to the access control call.
    ///
    func test_setValue_usesItemProtectionAndFlags() async throws {
        let item = makeItem()
        item.accessControlFlags = .biometryCurrentSet
        keychainService.accessControlResult = .success(makeAccessControl())
        keychainService.updateResult = .success(())

        try await subject.setValue("value", for: item)

        XCTAssertEqual(keychainService.accessControlFlags, .biometryCurrentSet)
        XCTAssertTrue(CFEqual(keychainService.accessControlProtection, kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
    }

    /// `setValue(_:for:)` rethrows when the update fails with an error other than `errSecItemNotFound`.
    ///
    func test_setValue_rethrows_whenUpdateFailsWithOtherError() async {
        let item = makeItem()
        keychainService.accessControlResult = .success(makeAccessControl())
        keychainService.updateResult = .failure(KeychainServiceError.osStatusError(errSecInteractionNotAllowed))

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecInteractionNotAllowed)) {
            try await subject.setValue("value", for: item)
        }
        XCTAssertTrue(keychainService.addCalls.isEmpty)
    }

    /// `setValue(_:for:)` rethrows when the add fails after a `errSecItemNotFound` update error.
    ///
    func test_setValue_rethrows_whenAddFails() async {
        let item = makeItem()
        keychainService.accessControlResult = .success(makeAccessControl())
        keychainService.updateResult = .failure(KeychainServiceError.osStatusError(errSecItemNotFound))
        keychainService.addResult = .failure(.osStatusError(errSecDuplicateItem))

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecDuplicateItem)) {
            try await subject.setValue("value", for: item)
        }
    }

    /// `setValue(_:for:)` rethrows when creating the access control fails, without calling update or add.
    ///
    func test_setValue_rethrows_whenAccessControlFails() async {
        let item = makeItem()
        keychainService.accessControlResult = .failure(.accessControlFailed(nil))

        await assertAsyncThrows(error: KeychainServiceError.accessControlFailed(nil)) {
            try await subject.setValue("value", for: item)
        }
        XCTAssertNil(keychainService.updateQuery)
        XCTAssertTrue(keychainService.addCalls.isEmpty)
    }

    // MARK: Tests - setValue(_:for:) Codable overload

    /// `setValue(_:for:)` JSON-encodes a `Codable` value and stores the resulting string.
    ///
    func test_setValue_codable_success() async throws {
        let item = makeItem()
        keychainService.accessControlResult = .success(makeAccessControl())
        keychainService.updateResult = .success(())

        try await subject.setValue(42, for: item)

        let expectedData = try JSONEncoder.defaultEncoder.encode(42)
        let storedData = (keychainService.updateAttributes as? [String: Any])?[kSecValueData as String] as? Data
        XCTAssertEqual(storedData, expectedData)
    }

    /// `setValue(_:for:)` rethrows when JSON encoding fails.
    ///
    func test_setValue_codable_encodingError_throws() async {
        let item = makeItem()
        keychainService.accessControlResult = .success(makeAccessControl())

        await assertAsyncThrows {
            try await subject.setValue(Double.nan, for: item)
        }
        XCTAssertNil(keychainService.updateQuery)
        XCTAssertTrue(keychainService.addCalls.isEmpty)
    }

    // MARK: Private Helpers

    private func makeItem(unformattedKey: String = "test_key") -> MockKeychainItem {
        let item = MockKeychainItem(unformattedKey: unformattedKey)
        item.protection = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return item
    }

    private func makeAccessControl() -> SecAccessControl {
        var error: Unmanaged<CFError>?
        return SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [], &error)!
    }
}
