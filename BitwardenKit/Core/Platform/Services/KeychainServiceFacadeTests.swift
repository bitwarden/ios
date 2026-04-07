import BitwardenKitMocks
import Foundation
import Security
import Testing

@testable import BitwardenKit

// MARK: - KeychainServiceFacadeTests

struct KeychainServiceFacadeTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let appIDSettingsStore: MockAppIDSettingsStore
    let keychainService: MockKeychainService
    let subject: DefaultKeychainServiceFacade

    // MARK: Setup

    init() {
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

    // MARK: Tests - deleteValue(for:)

    /// `deleteValue(for:)` deletes the item using the correct base query.
    @Test
    func deleteValue_success() async throws {
        let item = MockKeychainItem(unformattedKey: "delete_key")

        try await subject.deleteValue(for: item)

        let query = keychainService.deleteReceivedQuery as? [String: Any]
        #expect(query?[kSecAttrAccount as String] as? String == "test-prefix:test-app-ID:delete_key")
        #expect(query?[kSecAttrAccessGroup as String] as? String == "test-access-group")
        #expect(query?[kSecAttrService as String] as? String == "test-service")
        #expect(query?[kSecClass as String] as? String == kSecClassGenericPassword as String)
    }

    /// `deleteValue(for:)` rethrows errors from the keychain service.
    @Test
    func deleteValue_rethrows() async {
        let item = MockKeychainItem(unformattedKey: "delete_key")
        keychainService.deleteThrowableError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)

        await #expect(throws: KeychainServiceError.osStatusError(errSecInteractionNotAllowed)) {
            try await subject.deleteValue(for: item)
        }
    }

    // MARK: Tests - getValue(for:) -> String

    /// `getValue(for:)` returns the stored string when the keychain search succeeds.
    @Test
    func getValue_string_success() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")
        keychainService.searchReturnValue = [kSecValueData as String: Data("stored-value".utf8)] as AnyObject

        let result = try await subject.getValue(for: item)

        #expect(result == "stored-value")
        let searchQuery = keychainService.searchReceivedQuery as? [String: Any]
        #expect(searchQuery?[kSecAttrAccount as String] as? String == "test-prefix:test-app-ID:test_key")
        #expect(searchQuery?[kSecAttrAccessGroup as String] as? String == "test-access-group")
        #expect(searchQuery?[kSecAttrService as String] as? String == "test-service")
        #expect(searchQuery?[kSecClass as String] as? String == kSecClassGenericPassword as String)
        #expect(searchQuery?[kSecMatchLimit as String] as? String == kSecMatchLimitOne as String)
        #expect(searchQuery?[kSecReturnData as String] as? Bool == true)
        #expect(searchQuery?[kSecReturnAttributes as String] as? Bool == true)
    }

    /// `getValue(for:)` throws `keyNotFound` when the search returns `nil`.
    @Test
    func getValue_string_nilResult_throwsKeyNotFound() async {
        let item = MockKeychainItem(unformattedKey: "missing_key")
        keychainService.searchReturnValue = nil

        await #expect(throws: KeychainServiceError.keyNotFound(item)) {
            _ = try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` throws `keyNotFound` when the search returns an empty string.
    @Test
    func getValue_string_emptyString_throwsKeyNotFound() async {
        let item = MockKeychainItem(unformattedKey: "empty_key")
        keychainService.searchReturnValue = [kSecValueData as String: Data("".utf8)] as AnyObject

        await #expect(throws: KeychainServiceError.keyNotFound(item)) {
            _ = try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` throws `keyNotFound` when the search result is not a dictionary.
    @Test
    func getValue_string_nonDictionaryResult_throwsKeyNotFound() async {
        let item = MockKeychainItem(unformattedKey: "bad_result_key")
        keychainService.searchReturnValue = "unexpected-string" as AnyObject

        await #expect(throws: KeychainServiceError.keyNotFound(item)) {
            _ = try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` rethrows other keychain service errors as-is.
    @Test
    func getValue_string_otherKeychainError_rethrows() async {
        let item = MockKeychainItem(unformattedKey: "error_key")
        keychainService.searchThrowableError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)

        await #expect(throws: KeychainServiceError.osStatusError(errSecInteractionNotAllowed)) {
            _ = try await subject.getValue(for: item)
        }
    }

    // MARK: Tests - getValue(for:) -> T: Codable

    /// `getValue(for:)` decodes and returns a `Codable` value when the keychain search succeeds.
    @Test
    func getValue_codable_success() async throws {
        let item = MockKeychainItem(unformattedKey: "codable_key")
        keychainService.searchReturnValue = [kSecValueData as String: Data("42".utf8)] as AnyObject

        let result: Int = try await subject.getValue(for: item)

        #expect(result == 42)
    }

    /// `getValue(for:)` throws a decoding error when the stored string is not valid JSON for the target type.
    @Test
    func getValue_codable_invalidJSON_throwsDecodingError() async {
        let item = MockKeychainItem(unformattedKey: "bad_json_key")
        keychainService.searchReturnValue = [kSecValueData as String: Data("not-a-number".utf8)] as AnyObject

        // DecodingError is complex to construct for comparison, so we only assert that an error is thrown.
        await #expect(throws: (any Error).self) {
            let _: Int = try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` propagates `keyNotFound` when the underlying string getter throws.
    @Test
    func getValue_codable_keyNotFound_rethrows() async {
        let item = MockKeychainItem(unformattedKey: "missing_codable_key")
        keychainService.searchReturnValue = nil

        await #expect(throws: KeychainServiceError.keyNotFound(item)) {
            let _: Int = try await subject.getValue(for: item)
        }
    }

    /// `getValue(for:)` rethrows other keychain service errors as-is.
    @Test
    func getValue_codable_otherKeychainError_rethrows() async {
        let item = MockKeychainItem(unformattedKey: "error_codable_key")
        keychainService.searchThrowableError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)

        await #expect(throws: KeychainServiceError.osStatusError(errSecInteractionNotAllowed)) {
            let _: Int = try await subject.getValue(for: item)
        }
    }

    // MARK: Tests - setValue(_: String, for:)

    /// `setValue(_:for:)` updates the existing item when the update succeeds without calling `add`.
    @Test
    func setValue_updatesExistingItem() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")
        keychainService.accessControlReturnValue = try makeAccessControl()

        try await subject.setValue("new-value", for: item)

        #expect(!keychainService.addCalled)
        let updateReceivedArguments = try #require(keychainService.updateReceivedArguments)

        let updateQuery = try #require(updateReceivedArguments.query as? [String: Any])
        #expect(updateQuery[kSecAttrAccount as String] as? String == "test-prefix:test-app-ID:test_key")
        #expect(updateQuery[kSecAttrAccessGroup as String] as? String == "test-access-group")
        #expect(updateQuery[kSecAttrService as String] as? String == "test-service")

        let receivedAttributes = try #require(updateReceivedArguments.attributes as? [String: Any])
        let storedData = try #require(receivedAttributes[kSecValueData as String] as? Data)
        #expect(storedData == Data("new-value".utf8))
    }

    /// `setValue(_:for:)` falls through to `add` when the update returns `errSecItemNotFound`.
    @Test
    func setValue_addsNewItem_whenNotFound() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")
        keychainService.accessControlReturnValue = try makeAccessControl()
        keychainService.updateThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        try await subject.setValue("new-value", for: item)

        #expect(keychainService.addCallsCount == 1)
        let addAttributes = try #require(keychainService.addReceivedAttributes as? [String: Any])
        #expect(addAttributes[kSecAttrAccount as String] as? String == "test-prefix:test-app-ID:test_key")
        #expect(addAttributes[kSecAttrAccessGroup as String] as? String == "test-access-group")
        #expect(addAttributes[kSecAttrService as String] as? String == "test-service")
        #expect(addAttributes[kSecClass as String] as? String == kSecClassGenericPassword as String)

        let storedData = try #require(addAttributes[kSecValueData as String] as? Data)
        #expect(storedData == Data("new-value".utf8))
    }

    /// `setValue(_:for:)` passes the item's `protection` and `accessControlFlags` to the access control call.
    @Test
    func setValue_usesItemProtectionAndFlags() async throws {
        let item = MockKeychainItem(
            unformattedKey: "test_key",
            accessControlFlags: .biometryCurrentSet,
        )
        keychainService.accessControlReturnValue = try makeAccessControl()

        try await subject.setValue("value", for: item)

        #expect(keychainService.accessControlReceivedArguments?.flags == .biometryCurrentSet)
        let receivedProtection = try #require(keychainService.accessControlReceivedArguments?.protection)
        #expect(CFEqual(receivedProtection, kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
    }

    /// `setValue(_:for:)` rethrows when the update fails with an error other than `errSecItemNotFound`.
    @Test
    func setValue_rethrows_whenUpdateFailsWithOtherError() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")
        keychainService.accessControlReturnValue = try makeAccessControl()
        keychainService.updateThrowableError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)

        await #expect(throws: KeychainServiceError.osStatusError(errSecInteractionNotAllowed)) {
            try await subject.setValue("value", for: item)
        }
        #expect(!keychainService.addCalled)
    }

    /// `setValue(_:for:)` rethrows when the add fails after a `errSecItemNotFound` update error.
    @Test
    func setValue_rethrows_whenAddFails() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")
        keychainService.accessControlReturnValue = try makeAccessControl()
        keychainService.updateThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)
        keychainService.addThrowableError = KeychainServiceError.osStatusError(errSecDuplicateItem)

        await #expect(throws: KeychainServiceError.osStatusError(errSecDuplicateItem)) {
            try await subject.setValue("value", for: item)
        }
    }

    /// `setValue(_:for:)` rethrows when creating the access control fails, without calling update or add.
    @Test
    func setValue_rethrows_whenAccessControlFails() async {
        let item = MockKeychainItem(unformattedKey: "test_key")
        keychainService.accessControlThrowableError = KeychainServiceError.accessControlFailed(nil)

        await #expect(throws: KeychainServiceError.accessControlFailed(nil)) {
            try await subject.setValue("value", for: item)
        }
        #expect(!keychainService.updateCalled)
        #expect(!keychainService.addCalled)
    }

    // MARK: Tests - setValue(_: T: Codable, for:)

    /// `setValue(_:for:)` JSON-encodes a `Codable` value and stores the resulting string.
    ///
    @Test
    func setValue_codable_success() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")
        keychainService.accessControlReturnValue = try makeAccessControl()

        try await subject.setValue(42, for: item)

        let expectedData = try JSONEncoder.defaultEncoder.encode(42)
        let actualAttributes = try #require(keychainService.updateReceivedArguments?.attributes as? [String: Any])
        let storedData = try #require(actualAttributes[kSecValueData as String] as? Data)
        #expect(storedData == expectedData)
    }

    /// `setValue(_:for:)` rethrows when JSON encoding fails.
    @Test
    func setValue_codable_encodingError_throws() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")
        keychainService.accessControlReturnValue = try makeAccessControl()

        // EncodingError is complex to construct for comparison, so we only assert that an error is thrown.
        await #expect(throws: (any Error).self) {
            try await subject.setValue(Double.nan, for: item)
        }
        #expect(!keychainService.updateCalled)
        #expect(!keychainService.addCalled)
    }

    // MARK: Tests - setValue(_: T?: Codable, for:)

    /// `setValue(_:for:)` JSON-encodes and stores a non-nil optional `Codable` value.
    @Test
    func setValue_optionalCodable_nonNil_storesValue() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")
        keychainService.accessControlReturnValue = try makeAccessControl()

        try await subject.setValue(Optional(42), for: item)

        let expectedData = try JSONEncoder.defaultEncoder.encode(42)
        let actualAttributes = try #require(keychainService.updateReceivedArguments?.attributes as? [String: Any])
        let storedData = actualAttributes[kSecValueData as String] as? Data
        #expect(storedData == expectedData)
        #expect(!keychainService.deleteCalled)
    }

    /// `setValue(_:for:)` deletes the keychain item when the optional value is nil.
    @Test
    func setValue_optionalCodable_nil_deletesValue() async throws {
        let item = MockKeychainItem(unformattedKey: "optional_key")

        try await subject.setValue(Int?.none, for: item)

        #expect(!keychainService.updateCalled)
        #expect(!keychainService.addCalled)
        let query = keychainService.deleteReceivedQuery as? [String: Any]
        #expect(query?[kSecAttrAccount as String] as? String == "test-prefix:test-app-ID:optional_key")
    }

    // MARK: Tests - shared namespacing configuration

    /// With `.appScoped` namespacing, `keychainQueryValues` includes `kSecAttrService` in the query.
    ///
    @Test
    func keychainQueryValues_appScopedNamespacing_includesService() async {
        let item = MockKeychainItem(unformattedKey: "test_key")

        let query = await subject.keychainQueryValues(for: item)

        let dict = query as? [String: Any]
        #expect(dict?[kSecAttrService as String] as? String == "test-service")
        #expect(dict?[kSecClass as String] as? String == kSecClassGenericPassword as String)
    }

    /// With `.appScoped` namespacing, `keychainQueryValues` formats `kSecAttrAccount` as `prefix:appID:unformattedKey`.
    ///
    @Test
    func keychainQueryValues_appScopedNamespacing_usesFormattedKey() async {
        let item = MockKeychainItem(unformattedKey: "scoped_key")

        let query = await subject.keychainQueryValues(for: item)

        let dict = query as? [String: Any]
        #expect(dict?[kSecAttrAccount as String] as? String == "test-prefix:test-app-ID:scoped_key")
        #expect(dict?[kSecClass as String] as? String == kSecClassGenericPassword as String)
    }

    /// With `.shared` namespacing, `keychainQueryValues` uses the bare `unformattedKey` for `kSecAttrAccount`.
    ///
    @Test
    func keychainQueryValues_sharedNamespacing_usesBareKey() async {
        let item = MockKeychainItem(unformattedKey: "shared_key")
        let sharedSubject = makeSharedSubject()

        let query = await sharedSubject.keychainQueryValues(for: item)

        let dict = query as? [String: Any]
        #expect(dict?[kSecAttrAccount as String] as? String == "shared_key")
        #expect(dict?[kSecClass as String] as? String == kSecClassGenericPassword as String)
    }

    /// With `.shared` namespacing, `keychainQueryValues` omits `kSecAttrService` from the query.
    ///
    @Test
    func keychainQueryValues_sharedNamespacing_omitsService() async {
        let item = MockKeychainItem(unformattedKey: "test_key")
        let sharedSubject = makeSharedSubject()

        let query = await sharedSubject.keychainQueryValues(for: item)

        let dict = query as? [String: Any]
        #expect(dict?[kSecAttrService as String] == nil)
        #expect(dict?[kSecClass as String] as? String == kSecClassGenericPassword as String)
    }

    // MARK: Private Helpers

    private func makeSharedSubject() -> DefaultKeychainServiceFacade {
        DefaultKeychainServiceFacade(
            appSecAttrAccessGroup: "test-access-group",
            keychainService: keychainService,
            namespacing: .shared,
        )
    }

    private func makeAccessControl() throws -> SecAccessControl {
        var error: Unmanaged<CFError>?
        return try #require(
            SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [], &error),
            "Failed to create access control: \(String(describing: error?.takeRetainedValue()))",
        )
    }
} // swiftlint:disable:this file_length
