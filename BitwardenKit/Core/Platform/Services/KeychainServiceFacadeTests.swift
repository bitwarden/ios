import BitwardenKitMocks
import XCTest

@testable import BitwardenKit

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
            appSecAttrAccessGroup: "test-access-group",
            keychainService: keychainService,
            namespacing: .appScoped(
                appIDService: AppIDService(appIDSettingsStore: appIDSettingsStore),
                appSecAttrService: "test-service",
                storageKeyPrefix: "test-prefix",
            ),
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
        keychainService.searchReturnValue = [kSecValueData as String: Data("stored-value".utf8)] as AnyObject

        let result = try await subject.getValue(for: item)

        XCTAssertEqual(result, "stored-value")
        let searchQuery = keychainService.searchReceivedQuery as? [String: Any]
        XCTAssertEqual(searchQuery?[kSecAttrAccount as String] as? String, "test-prefix:test-app-ID:test_key")
        XCTAssertEqual(searchQuery?[kSecAttrAccessGroup as String] as? String, "test-access-group")
        XCTAssertEqual(searchQuery?[kSecAttrService as String] as? String, "test-service")
        XCTAssertEqual(searchQuery?[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(searchQuery?[kSecMatchLimit as String] as? String, kSecMatchLimitOne as String)
        XCTAssertEqual(searchQuery?[kSecReturnData as String] as? Bool, true)
        XCTAssertEqual(searchQuery?[kSecReturnAttributes as String] as? Bool, true)
    }

    /// `getValue(for:)` throws `keyNotFound` when the search returns `nil`.
    ///
    func test_getValue_string_nilResult_throwsKeyNotFound() async {
        let item = MockKeychainItem(unformattedKey: "missing_key")
        keychainService.searchReturnValue = nil

        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(item)) {
            _ = try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` throws `keyNotFound` when the search returns an empty string.
    ///
    func test_getValue_string_emptyString_throwsKeyNotFound() async {
        let item = MockKeychainItem(unformattedKey: "empty_key")
        keychainService.searchReturnValue = [kSecValueData as String: Data("".utf8)] as AnyObject

        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(item)) {
            _ = try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` throws `keyNotFound` when the search result is not a dictionary.
    ///
    func test_getValue_string_nonDictionaryResult_throwsKeyNotFound() async {
        let item = MockKeychainItem(unformattedKey: "bad_result_key")
        keychainService.searchReturnValue = "unexpected-string" as AnyObject

        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(item)) {
            _ = try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` rethrows errors from the keychain service.
    ///
    func test_getValue_string_keychainError_rethrows() async {
        let item = MockKeychainItem(unformattedKey: "error_key")
        keychainService.searchThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecItemNotFound)) {
            _ = try await subject.getValue(for: item)
        }
    }

    // MARK: Tests - getValue(for:) -> T: Codable

    /// `getValue(for:)` decodes and returns a `Codable` value when the keychain search succeeds.
    ///
    func test_getValue_codable_success() async throws {
        let item = MockKeychainItem(unformattedKey: "codable_key")
        keychainService.searchReturnValue = [kSecValueData as String: Data("42".utf8)] as AnyObject

        let result: Int = try await subject.getValue(for: item)

        XCTAssertEqual(result, 42)
    }

    /// `getValue(for:)` throws a decoding error when the stored string is not valid JSON for the target type.
    ///
    func test_getValue_codable_invalidJSON_throwsDecodingError() async {
        let item = MockKeychainItem(unformattedKey: "bad_json_key")
        keychainService.searchReturnValue = [kSecValueData as String: Data("not-a-number".utf8)] as AnyObject

        // DecodingError is complex to construct for comparison, so we only assert that an error is thrown.
        await assertAsyncThrows {
            let _: Int = try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` propagates `keyNotFound` when the underlying string getter throws.
    ///
    func test_getValue_codable_keyNotFound_rethrows() async {
        let item = MockKeychainItem(unformattedKey: "missing_codable_key")
        keychainService.searchReturnValue = nil

        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(item)) {
            let _: Int = try await subject.getValue(for: item)
        }
    }

    // MARK: Tests - setValue(_: String, for:)

    /// `setValue(_:for:)` updates the existing item when the update succeeds without calling `add`.
    ///
    func test_setValue_updatesExistingItem() async throws {
        let item = makeItem()
        keychainService.accessControlReturnValue = makeAccessControl()

        try await subject.setValue("new-value", for: item)

        XCTAssertFalse(keychainService.addCalled)
        let updateQuery = keychainService.updateReceivedArguments?.query as? [String: Any]
        XCTAssertEqual(updateQuery?[kSecAttrAccount as String] as? String, "test-prefix:test-app-ID:test_key")
        XCTAssertEqual(updateQuery?[kSecAttrAccessGroup as String] as? String, "test-access-group")
        XCTAssertEqual(updateQuery?[kSecAttrService as String] as? String, "test-service")
        let storedData = (keychainService.updateReceivedArguments?.attributes as? [String: Any])?[kSecValueData as String] as? Data
        XCTAssertEqual(storedData, Data("new-value".utf8))
    }

    /// `setValue(_:for:)` falls through to `add` when the update returns `errSecItemNotFound`.
    ///
    func test_setValue_addsNewItem_whenNotFound() async throws {
        let item = makeItem()
        keychainService.accessControlReturnValue = makeAccessControl()
        keychainService.updateThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        try await subject.setValue("new-value", for: item)

        XCTAssertEqual(keychainService.addCallsCount, 1)
        let addAttributes = keychainService.addReceivedAttributes as? [String: Any]
        XCTAssertEqual(addAttributes?[kSecAttrAccount as String] as? String, "test-prefix:test-app-ID:test_key")
        XCTAssertEqual(addAttributes?[kSecAttrAccessGroup as String] as? String, "test-access-group")
        XCTAssertEqual(addAttributes?[kSecAttrService as String] as? String, "test-service")
        XCTAssertEqual(addAttributes?[kSecClass as String] as? String, kSecClassGenericPassword as String)
        let storedData = addAttributes?[kSecValueData as String] as? Data
        XCTAssertEqual(storedData, Data("new-value".utf8))
    }

    /// `setValue(_:for:)` passes the item's `protection` and `accessControlFlags` to the access control call.
    ///
    func test_setValue_usesItemProtectionAndFlags() async throws {
        let item = makeItem()
        item.accessControlFlags = .biometryCurrentSet
        keychainService.accessControlReturnValue = makeAccessControl()

        try await subject.setValue("value", for: item)

        XCTAssertEqual(keychainService.accessControlReceivedArguments?.flags, .biometryCurrentSet)
        XCTAssertTrue(CFEqual(keychainService.accessControlReceivedArguments?.protection, kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
    }

    /// `setValue(_:for:)` rethrows when the update fails with an error other than `errSecItemNotFound`.
    ///
    func test_setValue_rethrows_whenUpdateFailsWithOtherError() async {
        let item = makeItem()
        keychainService.accessControlReturnValue = makeAccessControl()
        keychainService.updateThrowableError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecInteractionNotAllowed)) {
            try await subject.setValue("value", for: item)
        }
        XCTAssertFalse(keychainService.addCalled)
    }

    /// `setValue(_:for:)` rethrows when the add fails after a `errSecItemNotFound` update error.
    ///
    func test_setValue_rethrows_whenAddFails() async {
        let item = makeItem()
        keychainService.accessControlReturnValue = makeAccessControl()
        keychainService.updateThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)
        keychainService.addThrowableError = KeychainServiceError.osStatusError(errSecDuplicateItem)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecDuplicateItem)) {
            try await subject.setValue("value", for: item)
        }
    }

    /// `setValue(_:for:)` rethrows when creating the access control fails, without calling update or add.
    ///
    func test_setValue_rethrows_whenAccessControlFails() async {
        let item = makeItem()
        keychainService.accessControlThrowableError = KeychainServiceError.accessControlFailed(nil)

        await assertAsyncThrows(error: KeychainServiceError.accessControlFailed(nil)) {
            try await subject.setValue("value", for: item)
        }
        XCTAssertNil(keychainService.updateReceivedArguments)
        XCTAssertFalse(keychainService.addCalled)
    }

    // MARK: Tests - deleteValue(for:)

    /// `deleteValue(for:)` deletes the item using the correct base query.
    ///
    func test_deleteValue_success() async throws {
        let item = makeItem(unformattedKey: "delete_key")

        try await subject.deleteValue(for: item)

        let query = keychainService.deleteReceivedQuery as? [String: Any]
        XCTAssertEqual(query?[kSecAttrAccount as String] as? String, "test-prefix:test-app-ID:delete_key")
        XCTAssertEqual(query?[kSecAttrAccessGroup as String] as? String, "test-access-group")
        XCTAssertEqual(query?[kSecAttrService as String] as? String, "test-service")
        XCTAssertEqual(query?[kSecClass as String] as? String, kSecClassGenericPassword as String)
    }

    /// `deleteValue(for:)` rethrows errors from the keychain service.
    ///
    func test_deleteValue_rethrows() async {
        let item = makeItem()
        keychainService.deleteThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(errSecItemNotFound)) {
            try await subject.deleteValue(for: item)
        }
    }

    // MARK: Tests - setValue(_: T: Codable, for:)

    /// `setValue(_:for:)` JSON-encodes a `Codable` value and stores the resulting string.
    ///
    func test_setValue_codable_success() async throws {
        let item = makeItem()
        keychainService.accessControlReturnValue = makeAccessControl()

        try await subject.setValue(42, for: item)

        let expectedData = try JSONEncoder.defaultEncoder.encode(42)
        let storedData = (keychainService.updateReceivedArguments?.attributes as? [String: Any])?[kSecValueData as String] as? Data
        XCTAssertEqual(storedData, expectedData)
    }

    /// `setValue(_:for:)` rethrows when JSON encoding fails.
    ///
    func test_setValue_codable_encodingError_throws() async {
        let item = makeItem()
        keychainService.accessControlReturnValue = makeAccessControl()

        await assertAsyncThrows {
            try await subject.setValue(Double.nan, for: item)
        }
        XCTAssertNil(keychainService.updateReceivedArguments)
        XCTAssertFalse(keychainService.addCalled)
    }

    // MARK: Tests - setValue(_: T?: Codable, for:)

    /// `setValue(_:for:)` JSON-encodes and stores a non-nil optional `Codable` value.
    ///
    func test_setValue_optionalCodable_nonNil_storesValue() async throws {
        let item = makeItem()
        keychainService.accessControlReturnValue = makeAccessControl()

        try await subject.setValue(Optional(42), for: item)

        let expectedData = try JSONEncoder.defaultEncoder.encode(42)
        let storedData = (keychainService.updateReceivedArguments?.attributes as? [String: Any])?[kSecValueData as String] as? Data
        XCTAssertEqual(storedData, expectedData)
        XCTAssertFalse(keychainService.deleteCalled)
    }

    /// `setValue(_:for:)` deletes the keychain item when the optional value is nil.
    ///
    func test_setValue_optionalCodable_nil_deletesValue() async throws {
        let item = makeItem(unformattedKey: "optional_key")

        try await subject.setValue(Optional<Int>.none, for: item)

        XCTAssertNil(keychainService.updateReceivedArguments)
        XCTAssertFalse(keychainService.addCalled)
        let query = keychainService.deleteReceivedQuery as? [String: Any]
        XCTAssertEqual(query?[kSecAttrAccount as String] as? String, "test-prefix:test-app-ID:optional_key")
    }

    // MARK: Tests - shared namespacing configuration

    /// With `.appScoped` namespacing, `keychainQueryValues` includes `kSecAttrService` in the query.
    ///
    func test_keychainQueryValues_appScopedNamespacing_includesService() async {
        let item = makeItem()

        let query = await subject.keychainQueryValues(for: item)

        let dict = query as? [String: Any]
        XCTAssertEqual(dict?[kSecAttrService as String] as? String, "test-service")
        XCTAssertEqual(dict?[kSecClass as String] as? String, kSecClassGenericPassword as String)
    }

    /// With `.appScoped` namespacing, `keychainQueryValues` formats `kSecAttrAccount` as `prefix:appID:unformattedKey`.
    ///
    func test_keychainQueryValues_appScopedNamespacing_usesFormattedKey() async {
        let item = makeItem(unformattedKey: "scoped_key")

        let query = await subject.keychainQueryValues(for: item)

        let dict = query as? [String: Any]
        XCTAssertEqual(dict?[kSecAttrAccount as String] as? String, "test-prefix:test-app-ID:scoped_key")
        XCTAssertEqual(dict?[kSecClass as String] as? String, kSecClassGenericPassword as String)
    }

    /// With `.shared` namespacing, `keychainQueryValues` uses the bare `unformattedKey` for `kSecAttrAccount`.
    ///
    func test_keychainQueryValues_sharedNamespacing_usesBareKey() async {
        let item = makeItem(unformattedKey: "shared_key")
        let sharedSubject = makeSharedSubject()

        let query = await sharedSubject.keychainQueryValues(for: item)

        let dict = query as? [String: Any]
        XCTAssertEqual(dict?[kSecAttrAccount as String] as? String, "shared_key")
        XCTAssertEqual(dict?[kSecClass as String] as? String, kSecClassGenericPassword as String)
    }

    /// With `.shared` namespacing, `keychainQueryValues` omits `kSecAttrService` from the query.
    ///
    func test_keychainQueryValues_sharedNamespacing_omitsService() async {
        let item = makeItem()
        let sharedSubject = makeSharedSubject()

        let query = await sharedSubject.keychainQueryValues(for: item)

        let dict = query as? [String: Any]
        XCTAssertNil(dict?[kSecAttrService as String])
        XCTAssertEqual(dict?[kSecClass as String] as? String, kSecClassGenericPassword as String)
    }

    // MARK: Private Helpers

    private func makeSharedSubject() -> DefaultKeychainServiceFacade {
        DefaultKeychainServiceFacade(
            appSecAttrAccessGroup: "test-access-group",
            keychainService: keychainService,
            namespacing: .shared,
        )
    }

    private func makeItem(unformattedKey: String = "test_key") -> MockKeychainItem {
        let item = MockKeychainItem(unformattedKey: unformattedKey)
        item.protection = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return item
    }

    private func makeAccessControl() -> SecAccessControl {
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [], &error) else {
            XCTFail("Failed to create access control: \(String(describing: error?.takeRetainedValue()))")
            // XCTFail does not halt execution, so fatalError satisfies the non-optional return type.
            fatalError("Unreachable")
        }
        return accessControl
    }
}
