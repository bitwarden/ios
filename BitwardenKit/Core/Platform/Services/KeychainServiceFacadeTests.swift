import BitwardenKitMocks
import Foundation
import Security
import Testing

@testable import BitwardenKit

// MARK: - KeychainServiceFacadeTests

struct KeychainServiceFacadeTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let keychainService: MockKeychainService
    let subject: DefaultKeychainServiceFacade

    // MARK: Setup

    init() {
        let appIDSettingsStore = MockAppIDSettingsStore()
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

    // MARK: Tests - deleteIdentity(for:)

    /// `deleteIdentity(for:)` deletes the identity using the correct query attributes.
    @Test
    func deleteIdentity_usesCorrectQuery() async throws {
        let item = MockKeychainItem(unformattedKey: "clientCertificateIdentity_abc123")

        try await subject.deleteIdentity(for: item)

        let query = try #require(keychainService.deleteReceivedQuery as? [String: Any])
        #expect(query[kSecClass as String] as? String == kSecClassIdentity as String)
        #expect(query[kSecAttrLabel as String] as? String == "test-prefix:test-app-ID:clientCertificateIdentity_abc123")
        #expect(query[kSecAttrAccessGroup as String] as? String == "test-access-group")
        #expect(query.count == 3)
    }

    /// `deleteIdentity(for:)` rethrows errors from the keychain service.
    @Test
    func deleteIdentity_rethrows() async {
        let item = MockKeychainItem(unformattedKey: "clientCertificateIdentity_abc123")
        keychainService.deleteThrowableError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)

        await #expect(throws: KeychainServiceError.osStatusError(errSecInteractionNotAllowed)) {
            try await subject.deleteIdentity(for: item)
        }
    }

    // MARK: Tests - getIdentity(for:)

    /// `getIdentity(for:)` searches with the correct query attributes.
    @Test
    func getIdentity_usesCorrectQuery() async throws {
        let item = MockKeychainItem(unformattedKey: "clientCertificateIdentity_abc123")
        keychainService.searchReturnValue = nil

        _ = try await subject.getIdentity(for: item)

        let query = try #require(keychainService.searchReceivedQuery as? [String: Any])
        #expect(query[kSecClass as String] as? String == kSecClassIdentity as String)
        #expect(query[kSecAttrLabel as String] as? String == "test-prefix:test-app-ID:clientCertificateIdentity_abc123")
        #expect(query[kSecAttrAccessGroup as String] as? String == "test-access-group")
        #expect(query[kSecReturnRef as String] as? Bool == true)
        #expect(query[kSecMatchLimit as String] as? String == kSecMatchLimitOne as String)
    }

    /// `getIdentity(for:)` returns nil when the search result is nil.
    @Test
    func getIdentity_returnsNil_whenSearchReturnsNil() async throws {
        let item = MockKeychainItem(unformattedKey: "clientCertificateIdentity_abc123")
        keychainService.searchReturnValue = nil

        let result = try await subject.getIdentity(for: item)

        #expect(result == nil)
    }

    /// `getIdentity(for:)` returns nil on errSecItemNotFound.
    @Test
    func getIdentity_returnsNil_onItemNotFound() async throws {
        let item = MockKeychainItem(unformattedKey: "clientCertificateIdentity_abc123")
        keychainService.searchThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        let result = try await subject.getIdentity(for: item)

        #expect(result == nil)
    }

    /// `getIdentity(for:)` rethrows unexpected keychain errors.
    @Test
    func getIdentity_rethrows_unexpectedError() async {
        let item = MockKeychainItem(unformattedKey: "clientCertificateIdentity_abc123")
        keychainService.searchThrowableError = KeychainServiceError.osStatusError(errSecInteractionNotAllowed)

        await #expect(throws: KeychainServiceError.osStatusError(errSecInteractionNotAllowed)) {
            _ = try await subject.getIdentity(for: item)
        }
    }

    /// `getIdentity(for:)` returns the stored identity when one is found.
    @Test
    func getIdentity_returnsIdentity_whenPresent() async throws {
        let item = MockKeychainItem(unformattedKey: "clientCertificateIdentity_abc123")
        let identity = try makeTestIdentity()
        keychainService.searchReturnValue = identity

        let result = try await subject.getIdentity(for: item)

        #expect(result != nil)
    }

    // MARK: Tests - setIdentity(_:for:)

    /// `setIdentity(_:for:)` adds the identity with the correct attributes.
    @Test
    func setIdentity_addsWithCorrectAttributes() async throws {
        let item = MockKeychainItem(unformattedKey: "clientCertificateIdentity_abc123")
        let identity = try makeTestIdentity()

        try await subject.setIdentity(identity, for: item)

        let addAttributes = try #require(keychainService.addReceivedAttributes as? [String: Any])
        #expect(addAttributes[kSecClass as String] as? String == kSecClassIdentity as String)
        #expect(
            addAttributes[kSecAttrLabel as String] as? String
                == "test-prefix:test-app-ID:clientCertificateIdentity_abc123",
        )
        #expect(addAttributes[kSecAttrAccessGroup as String] as? String == "test-access-group")
        #expect(CFEqual(addAttributes[kSecAttrAccessible as String] as CFTypeRef?, item.protection))
        #expect(addAttributes[kSecValueRef as String] != nil)
    }

    /// `setIdentity(_:for:)` rethrows errors from the keychain service.
    @Test
    func setIdentity_rethrows() async throws {
        let item = MockKeychainItem(unformattedKey: "clientCertificateIdentity_abc123")
        let identity = try makeTestIdentity()
        keychainService.addThrowableError = KeychainServiceError.osStatusError(errSecDuplicateItem)

        await #expect(throws: KeychainServiceError.osStatusError(errSecDuplicateItem)) {
            try await subject.setIdentity(identity, for: item)
        }
    }

    // MARK: Tests - deleteValue(for:)

    /// `deleteValue(for:)` deletes the item using the correct base query.
    @Test
    func deleteValue_success() async throws {
        let item = MockKeychainItem(unformattedKey: "delete_key")

        try await subject.deleteValue(for: item)

        let query = try #require(keychainService.deleteReceivedQuery as? [String: Any])
        #expect(query[kSecAttrAccount as String] as? String == "test-prefix:test-app-ID:delete_key")
        #expect(query[kSecAttrAccessGroup as String] as? String == "test-access-group")
        #expect(query[kSecAttrService as String] as? String == "test-service")
        #expect(query[kSecClass as String] as? String == kSecClassGenericPassword as String)
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
        let searchQuery = try #require(keychainService.searchReceivedQuery as? [String: Any])
        #expect(searchQuery[kSecAttrAccount as String] as? String == "test-prefix:test-app-ID:test_key")
        #expect(searchQuery[kSecAttrAccessGroup as String] as? String == "test-access-group")
        #expect(searchQuery[kSecAttrService as String] as? String == "test-service")
        #expect(searchQuery[kSecClass as String] as? String == kSecClassGenericPassword as String)
        #expect(searchQuery[kSecMatchLimit as String] as? String == kSecMatchLimitOne as String)
        #expect(searchQuery[kSecReturnData as String] as? Bool == true)
        #expect(searchQuery[kSecReturnAttributes as String] as? Bool == true)
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

        let accessControlArgs = try #require(keychainService.accessControlReceivedArguments)
        #expect(accessControlArgs.flags == .biometryCurrentSet)
        #expect(CFEqual(accessControlArgs.protection, kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
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
        let storedData = try #require(actualAttributes[kSecValueData as String] as? Data)
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
        let query = try #require(keychainService.deleteReceivedQuery as? [String: Any])
        #expect(query[kSecAttrAccount as String] as? String == "test-prefix:test-app-ID:optional_key")
    }

    // MARK: Tests - shared namespacing configuration

    /// With `.appScoped` namespacing, `keychainQueryValues` includes `kSecAttrService` in the query.
    ///
    @Test
    func keychainQueryValues_appScopedNamespacing_includesService() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")

        let query = await subject.keychainQueryValues(for: item)

        let dict = try #require(query as? [String: Any])
        #expect(dict[kSecAttrService as String] as? String == "test-service")
        #expect(dict[kSecClass as String] as? String == kSecClassGenericPassword as String)
    }

    /// With `.appScoped` namespacing, `keychainQueryValues` formats `kSecAttrAccount` as `prefix:appID:unformattedKey`.
    ///
    @Test
    func keychainQueryValues_appScopedNamespacing_usesFormattedKey() async throws {
        let item = MockKeychainItem(unformattedKey: "scoped_key")

        let query = await subject.keychainQueryValues(for: item)

        let dict = try #require(query as? [String: Any])
        #expect(dict[kSecAttrAccount as String] as? String == "test-prefix:test-app-ID:scoped_key")
        #expect(dict[kSecClass as String] as? String == kSecClassGenericPassword as String)
    }

    /// With `.shared` namespacing, `keychainQueryValues` uses the bare `unformattedKey` for `kSecAttrAccount`.
    ///
    @Test
    func keychainQueryValues_sharedNamespacing_usesBareKey() async throws {
        let item = MockKeychainItem(unformattedKey: "shared_key")
        let sharedSubject = makeSharedSubject()

        let query = await sharedSubject.keychainQueryValues(for: item)

        let dict = try #require(query as? [String: Any])
        #expect(dict[kSecAttrAccount as String] as? String == "shared_key")
        #expect(dict[kSecClass as String] as? String == kSecClassGenericPassword as String)
    }

    /// With `.shared` namespacing, `keychainQueryValues` omits `kSecAttrService` from the query.
    ///
    @Test
    func keychainQueryValues_sharedNamespacing_omitsService() async throws {
        let item = MockKeychainItem(unformattedKey: "test_key")
        let sharedSubject = makeSharedSubject()

        let query = await sharedSubject.keychainQueryValues(for: item)

        let dict = try #require(query as? [String: Any])
        #expect(dict[kSecAttrService as String] == nil)
        #expect(dict[kSecClass as String] as? String == kSecClassGenericPassword as String)
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

    /// Creates a `SecIdentity` from a pre-generated self-signed test PKCS#12 (password: "testpassword").
    private func makeTestIdentity() throws -> SecIdentity {
        // swiftlint:disable:next line_length
        let p12Base64 = "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"
        let p12Data = try #require(Data(base64Encoded: p12Base64))
        var importResult: CFArray?
        let status = SecPKCS12Import(
            p12Data as CFData,
            [kSecImportExportPassphrase: "testpassword"] as CFDictionary,
            &importResult,
        )
        guard status == errSecSuccess,
              let items = importResult as? [[String: Any]],
              let identityRef = items.first?[kSecImportItemIdentity as String] else {
            throw BitwardenError.dataError("Failed to import test identity")
        }
        // swiftlint:disable:next force_cast
        return identityRef as! SecIdentity
    }
} // swiftlint:disable:this file_length
