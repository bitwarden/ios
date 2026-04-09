import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

// MARK: - KeychainRepositoryTests

final class KeychainRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appIDSettingsStore: MockAppIDSettingsStore!
    var keychainService: MockKeychainService!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appIDSettingsStore = MockAppIDSettingsStore()
        keychainService = MockKeychainService()
        subject = DefaultKeychainRepository(
            appIDService: AppIDService(
                appIDSettingsStore: appIDSettingsStore,
            ),
            keychainService: keychainService,
        )
    }

    override func tearDown() {
        super.tearDown()

        appIDSettingsStore = nil
        keychainService = nil
        subject = nil
    }

    // MARK: Tests

    /// The service provides a kSecAttrService value.
    ///
    func test_appSecAttrService() {
        XCTAssertEqual(
            Bundle.main.appIdentifier,
            subject.appSecAttrService,
        )
    }

    /// The service provides a kSecAttrAccessGroup value.
    ///
    func test_appSecAttrAccessGroup() {
        XCTAssertEqual(
            Bundle.main.keychainAccessGroup,
            subject.appSecAttrAccessGroup,
        )
    }

    /// `deleteUserAuthKey` failures rethrow.
    ///
    func test_delete_error_onDelete() async {
        keychainService.deleteResult = .failure(.osStatusError(-1))
        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            try await subject.deleteUserAuthKey(for: .biometrics(userId: "123"))
        }
    }

    /// `deleteUserAuthKey` succeeds quietly.
    ///
    func test_delete_success() async throws {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        keychainService.deleteResult = .success(())
        let expectedQuery = await subject.keychainQueryValues(for: item)

        try await subject.deleteUserAuthKey(for: item)
        XCTAssertEqual(
            keychainService.deleteQueries,
            [expectedQuery],
        )
    }

    /// `deleteAllItems` deletes items for all classes.
    func test_deleteAllItems() async throws {
        try await subject.deleteAllItems()

        XCTAssertEqual(
            keychainService.deleteQueries,
            [
                [kSecClass: kSecClassGenericPassword] as CFDictionary,
                [kSecClass: kSecClassInternetPassword] as CFDictionary,
                [kSecClass: kSecClassCertificate] as CFDictionary,
                [kSecClass: kSecClassKey] as CFDictionary,
                [kSecClass: kSecClassIdentity] as CFDictionary,
            ],
        )
    }

    /// `deleteAuthenticatorVaultKey` deletes the stored Authenticator Vault Key with the correct query values.
    ///
    func test_deleteAuthenticatorVaultKey_success() async throws {
        let item = BitwardenKeychainItem.authenticatorVaultKey(userId: "1")
        keychainService.deleteResult = .success(())
        let expectedQuery = await subject.keychainQueryValues(for: item)

        try await subject.deleteAuthenticatorVaultKey(userId: "1")
        XCTAssertEqual(
            keychainService.deleteQueries,
            [expectedQuery],
        )
    }

    /// `deleteItems(for:)` deletes items for a specific user.
    func test_deleteItems_forUserId() async throws {
        try await subject.deleteItems(for: "1")

        let expectedQueries = await [
            subject.keychainQueryValues(for: .accessToken(userId: "1")),
            subject.keychainQueryValues(for: .authenticatorVaultKey(userId: "1")),
            subject.keychainQueryValues(for: .biometrics(userId: "1")),
            subject.keychainQueryValues(for: .lastActiveTime(userId: "1")),
            subject.keychainQueryValues(for: .neverLock(userId: "1")),
            subject.keychainQueryValues(for: .refreshToken(userId: "1")),
            subject.keychainQueryValues(for: .unsuccessfulUnlockAttempts(userId: "1")),
        ]

        XCTAssertEqual(
            keychainService.deleteQueries,
            expectedQueries,
        )
    }

    /// `deleteDeviceKey` succeeds quietly.
    ///
    func test_deleteDeviceKey_success() async throws {
        let item = BitwardenKeychainItem.deviceKey(userId: "1")
        keychainService.deleteResult = .success(())
        let expectedQuery = await subject.keychainQueryValues(for: item)

        try await subject.deleteDeviceKey(userId: "1")
        XCTAssertEqual(
            keychainService.deleteQueries,
            [expectedQuery],
        )
    }

    /// `deletePendingAdminLoginRequest` succeeds quietly.
    ///
    func test_deletePendingAdminLoginRequest_success() async throws {
        let item = BitwardenKeychainItem.pendingAdminLoginRequest(userId: "1")
        keychainService.deleteResult = .success(())
        let expectedQuery = await subject.keychainQueryValues(for: item)

        try await subject.deletePendingAdminLoginRequest(userId: "1")
        XCTAssertEqual(
            keychainService.deleteQueries,
            [expectedQuery],
        )
    }

    /// The service should generate a storage key for a` KeychainItem`.
    ///
    func test_formattedKey_biometrics() async {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        appIDSettingsStore.appID = "testAppID"
        let formattedKey = await subject.formattedKey(for: item)
        let expectedKey = String(format: subject.storageKeyFormat, "testAppID", item.unformattedKey)

        XCTAssertEqual(
            formattedKey,
            expectedKey,
        )
    }

    /// The service should generate a storage key for a` KeychainItem`.
    ///
    func test_formattedKey_neverLock() async {
        let item = BitwardenKeychainItem.neverLock(userId: "123")
        appIDSettingsStore.appID = "testAppID"
        let formattedKey = await subject.formattedKey(for: item)
        let expectedKey = String(format: subject.storageKeyFormat, "testAppID", item.unformattedKey)

        XCTAssertEqual(
            formattedKey,
            expectedKey,
        )
    }

    /// `getAccessToken(userId:)` returns the stored access token.
    func test_getAccessToken() async throws {
        keychainService.setSearchResultData(string: "ACCESS_TOKEN")
        let accessToken = try await subject.getAccessToken(userId: "1")
        XCTAssertEqual(accessToken, "ACCESS_TOKEN")
    }

    /// `getAccessToken(userId:)` throws an error if one occurs.
    func test_getAccessToken_error() async {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.accessToken(userId: "1"))
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getAccessToken(userId: "1")
        }
    }

    /// `getAuthenticatorVaultKey(userId:)` returns the stored authenticator vault key.
    func test_getAuthenticatorVaultKey() async throws {
        keychainService.setSearchResultData(string: "AUTHENTICATOR_VAULT_KEY")
        let authVaultKey = try await subject.getAuthenticatorVaultKey(userId: "1")
        XCTAssertEqual(authVaultKey, "AUTHENTICATOR_VAULT_KEY")
    }

    /// `getAuthenticatorVaultKey(userId:)` throws an error if one occurs.
    func test_getAuthenticatorVaultKey_error() async {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.authenticatorVaultKey(userId: "1"))
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getAuthenticatorVaultKey(userId: "1")
        }
    }

    /// `getDeviceKey(userId:)` returns the stored device key.
    func test_getDeviceKey() async throws {
        keychainService.setSearchResultData(string: "DEVICE_KEY")
        let deviceKey = try await subject.getDeviceKey(userId: "1")
        XCTAssertEqual(deviceKey, "DEVICE_KEY")
    }

    /// `getDeviceKey(userId:)` throws an error if a non-keyNotFound error occurs.
    func test_getDeviceKey_error() async {
        let error = KeychainServiceError.osStatusError(-1)
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getDeviceKey(userId: "1")
        }
    }

    /// `getDeviceKey(userId:)` returns `nil` when the key is not found.
    func test_getDeviceKey_notFound() async throws {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.deviceKey(userId: "1"))
        keychainService.searchResult = .failure(error)
        let deviceKey = try await subject.getDeviceKey(userId: "1")
        XCTAssertNil(deviceKey)
    }

    /// `getPendingAdminLoginRequest(userId:)` returns the stored pending admin login request.
    func test_getPendingAdminLoginRequest() async throws {
        keychainService.setSearchResultData(string: "PENDING_ADMIN_LOGIN_REQUEST")
        let request = try await subject.getPendingAdminLoginRequest(userId: "1")
        XCTAssertEqual(request, "PENDING_ADMIN_LOGIN_REQUEST")
    }

    /// `getPendingAdminLoginRequest(userId:)` throws an error if a non-keyNotFound error occurs.
    func test_getPendingAdminLoginRequest_error() async {
        let error = KeychainServiceError.osStatusError(-1)
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getPendingAdminLoginRequest(userId: "1")
        }
    }

    /// `getPendingAdminLoginRequest(userId:)` returns `nil` when the key is not found.
    func test_getPendingAdminLoginRequest_notFound() async throws {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.pendingAdminLoginRequest(userId: "1"))
        keychainService.searchResult = .failure(error)
        let request = try await subject.getPendingAdminLoginRequest(userId: "1")
        XCTAssertNil(request)
    }

    /// `getRefreshToken(userId:)` returns the stored refresh token.
    func test_getRefreshToken() async throws {
        keychainService.setSearchResultData(string: "REFRESH_TOKEN")
        let accessToken = try await subject.getRefreshToken(userId: "1")
        XCTAssertEqual(accessToken, "REFRESH_TOKEN")
    }

    /// `getRefreshToken(userId:)` throws an error if one occurs.
    func test_getRefreshToken_error() async {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.refreshToken(userId: "1"))
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getRefreshToken(userId: "1")
        }
    }

    /// `getUserAuthKeyValue(_:)` failures rethrow.
    ///
    func test_getUserAuthKeyValue_error_searchError() async {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        let searchError = KeychainServiceError.osStatusError(-1)
        keychainService.searchResult = .failure(searchError)
        await assertAsyncThrows(error: searchError) {
            _ = try await subject.getUserAuthKeyValue(for: item)
        }
    }

    /// `getUserAuthKeyValue(_:)` errors if the search results are not in the correct format.
    ///
    func test_getUserAuthKeyValue_error_malformedData() async {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        let notFoundError = KeychainServiceError.keyNotFound(item)
        let results = [
            kSecValueData: Data(),
        ] as CFDictionary
        keychainService.searchResult = .success(results)
        await assertAsyncThrows(error: notFoundError) {
            _ = try await subject.getUserAuthKeyValue(for: .biometrics(userId: "123"))
        }
    }

    /// `getUserAuthKeyValue(_:)` errors if the search results are not in the correct format.
    ///
    func test_getUserAuthKeyValue_error_unexpectedResult() async {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        let notFoundError = KeychainServiceError.keyNotFound(item)
        let results = [
            kSecValueData: 1,
        ] as CFDictionary
        keychainService.searchResult = .success(results)
        await assertAsyncThrows(error: notFoundError) {
            _ = try await subject.getUserAuthKeyValue(for: .biometrics(userId: "123"))
        }
    }

    /// `getUserAuthKeyValue(_:)` errors if the search results are empty.
    ///
    func test_getUserAuthKeyValue_error_nilResult() async {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        let notFoundError = KeychainServiceError.keyNotFound(item)
        keychainService.searchResult = .success(nil)
        await assertAsyncThrows(error: notFoundError) {
            _ = try await subject.getUserAuthKeyValue(for: .biometrics(userId: "123"))
        }
    }

    /// `getUserAuthKeyValue(_:)` returns a string on success.
    ///
    func test_getUserAuthKeyValue_error_success() async throws {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        let expectedKey = "1234"
        let results = [
            kSecValueData: Data("1234".utf8),
        ] as CFDictionary
        keychainService.searchResult = .success(results)
        let key = try await subject.getUserAuthKeyValue(for: item)
        XCTAssertEqual(key, expectedKey)
    }

    /// The service should generate keychain Query Key/Values` KeychainItem`.
    ///
    func test_keychainQueryValues_biometrics() async {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        appIDSettingsStore.appID = "testAppID"
        let formattedKey = await subject.formattedKey(for: item)
        let queryValues = await subject.keychainQueryValues(for: item)
        let expectedResult = [
            kSecAttrAccount: formattedKey,
            kSecAttrAccessGroup: subject.appSecAttrAccessGroup,
            kSecAttrService: subject.appSecAttrService,
            kSecClass: kSecClassGenericPassword,
        ] as CFDictionary

        XCTAssertEqual(
            queryValues,
            expectedResult,
        )
    }

    /// The service should generate keychain Query Key/Values` KeychainItem`.
    ///
    func test_keychainQueryValues_neverLock() async {
        let item = BitwardenKeychainItem.neverLock(userId: "123")
        appIDSettingsStore.appID = "testAppID"
        let formattedKey = await subject.formattedKey(for: item)
        let queryValues = await subject.keychainQueryValues(for: item)
        let expectedResult = [
            kSecAttrAccount: formattedKey,
            kSecAttrAccessGroup: subject.appSecAttrAccessGroup,
            kSecAttrService: subject.appSecAttrService,
            kSecClass: kSecClassGenericPassword,
        ] as CFDictionary

        XCTAssertEqual(
            queryValues,
            expectedResult,
        )
    }

    /// `setAccessToken(userId:)` stored the access token.
    func test_setAccessToken() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [],
                nil,
            )!,
        )
        keychainService.setSearchResultData(string: "ACCESS_TOKEN")
        try await subject.setAccessToken("ACCESS_TOKEN", userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        try XCTAssertEqual(
            String(data: XCTUnwrap(attributes[kSecValueData] as? Data), encoding: .utf8),
            "ACCESS_TOKEN",
        )
        let protection = try XCTUnwrap(keychainService.accessControlProtection as? String)
        XCTAssertEqual(protection, String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly))
    }

    /// `setAccessToken(userId:)` throws an error if one occurs.
    func test_setAccessToken_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainService.addResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.setAccessToken("ACCESS_TOKEN", userId: "1")
        }
    }

    /// `setAuthenticatorVaultKey(userId:)` stores the authenticator vault key.
    func test_setAuthenticatorVaultKey() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                [],
                nil,
            )!,
        )
        keychainService.setSearchResultData(string: "AUTHENTICATOR_VAULT_KEY")
        try await subject.setAuthenticatorVaultKey("AUTHENTICATOR_VAULT_KEY", userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        try XCTAssertEqual(
            String(data: XCTUnwrap(attributes[kSecValueData] as? Data), encoding: .utf8),
            "AUTHENTICATOR_VAULT_KEY",
        )
        let protection = try XCTUnwrap(keychainService.accessControlProtection as? String)
        XCTAssertEqual(protection, String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly))
    }

    /// `setAuthenticatorVaultKey(userId:)` throws an error if one occurs.
    func test_setAuthenticatorVaultKey_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainService.addResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.setAuthenticatorVaultKey("AUTHENTICATOR_VAULT_KEY", userId: "1")
        }
    }

    /// `setRefreshToken(userId:)` stored the refresh token.
    func test_setRefreshToken() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                [],
                nil,
            )!,
        )
        keychainService.setSearchResultData(string: "REFRESH_TOKEN")
        try await subject.setRefreshToken("REFRESH_TOKEN", userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        try XCTAssertEqual(
            String(data: XCTUnwrap(attributes[kSecValueData] as? Data), encoding: .utf8),
            "REFRESH_TOKEN",
        )
        let protection = try XCTUnwrap(keychainService.accessControlProtection as? String)
        XCTAssertEqual(protection, String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly))
    }

    /// `setRefreshToken(userId:)` throws an error if one occurs.
    func test_setRefreshToken_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainService.addResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.setRefreshToken("REFRESH_TOKEN", userId: "1")
        }
    }

    /// `setUserAuthKey(_:)` failures rethrow.
    ///
    func test_setUserAuthKey_error_accessControl() async {
        let newKey = "123"
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        let accessError = KeychainServiceError.accessControlFailed(nil)
        keychainService.accessControlResult = .failure(accessError)
        keychainService.addResult = .success(())
        await assertAsyncThrows(error: accessError) {
            _ = try await subject.setUserAuthKey(for: item, value: newKey)
        }
    }

    /// `setUserAuthKey(_:)` failures rethrow.
    ///
    func test_setUserAuthKey_error_onSet() async {
        let newKey = "123"
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        let addError = KeychainServiceError.osStatusError(-1)
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                item.accessControlFlags ?? [],
                nil,
            )!,
        )
        keychainService.addResult = .failure(addError)
        await assertAsyncThrows(error: addError) {
            _ = try await subject.setUserAuthKey(for: .biometrics(userId: "123"), value: newKey)
        }
    }

    /// `setUserAuthKey(_:)` succeeds quietly.
    ///
    func test_setUserAuthKey_success_biometrics() async throws {
        let newKey = "123"
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                item.accessControlFlags ?? [],
                nil,
            )!,
        )
        keychainService.addResult = .success(())
        try await subject.setUserAuthKey(for: item, value: newKey)
        XCTAssertEqual(keychainService.accessControlFlags, .biometryCurrentSet)
        let protection = try XCTUnwrap(keychainService.accessControlProtection as? String)
        XCTAssertEqual(protection, String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
    }

    /// `setUserAuthKey(_:)` succeeds quietly.
    ///
    func test_setUserAuthKey_success_neverlock() async throws {
        let newKey = "123"
        let item = BitwardenKeychainItem.neverLock(userId: "123")
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                item.accessControlFlags ?? [],
                nil,
            )!,
        )
        keychainService.addResult = .success(())
        try await subject.setUserAuthKey(for: item, value: newKey)
        XCTAssertEqual(keychainService.accessControlFlags, [])
        let protection = try XCTUnwrap(keychainService.accessControlProtection as? String)
        XCTAssertEqual(protection, String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
    }

    /// `setValue(_:for:)` attempts to update before adding when item doesn't exist.
    ///
    func test_setValue_addsNewItem_afterUpdateFails() async throws {
        let newKey = "test-value"
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            item.accessControlFlags ?? [],
            nil,
        )!

        keychainService.accessControlResult = .success(accessControl)
        keychainService.updateResult = .failure(KeychainServiceError.osStatusError(errSecItemNotFound))
        keychainService.addResult = .success(())

        try await subject.setValue(newKey, for: item)

        // Verify update was attempted first
        let updateQuery = try XCTUnwrap(keychainService.updateQuery as? [CFString: Any])
        let expectedFormattedKey = await subject.formattedKey(for: item)
        try XCTAssertEqual(XCTUnwrap(updateQuery[kSecAttrAccount] as? String), expectedFormattedKey)
        try XCTAssertEqual(XCTUnwrap(updateQuery[kSecAttrAccessGroup] as? String), subject.appSecAttrAccessGroup)
        try XCTAssertEqual(XCTUnwrap(updateQuery[kSecAttrService] as? String), subject.appSecAttrService)
        try XCTAssertEqual(XCTUnwrap(updateQuery[kSecClass] as? String), String(kSecClassGenericPassword))
        XCTAssertNil(updateQuery[kSecValueData])
        XCTAssertNil(updateQuery[kSecAttrAccessControl])

        let updateAttributes = try XCTUnwrap(keychainService.updateAttributes as? [CFString: Any])
        XCTAssertNotNil(updateAttributes[kSecValueData])
        XCTAssertNotNil(updateAttributes[kSecAttrAccessControl])
        let updateValueData = try XCTUnwrap(updateAttributes[kSecValueData] as? Data)
        XCTAssertEqual(String(data: updateValueData, encoding: .utf8), newKey)
        XCTAssertEqual(updateAttributes.count, 2)

        // Verify add was called after update failed
        let addAttributes = try XCTUnwrap(keychainService.addAttributes as? [CFString: Any])
        let addValueData = try XCTUnwrap(addAttributes[kSecValueData] as? Data)
        XCTAssertEqual(String(data: addValueData, encoding: .utf8), newKey)
        XCTAssertNotNil(addAttributes[kSecAttrAccessControl])
        try XCTAssertEqual(XCTUnwrap(addAttributes[kSecAttrAccount] as? String), expectedFormattedKey)
        try XCTAssertEqual(XCTUnwrap(addAttributes[kSecAttrAccessGroup] as? String), subject.appSecAttrAccessGroup)
        try XCTAssertEqual(XCTUnwrap(addAttributes[kSecAttrService] as? String), subject.appSecAttrService)
        try XCTAssertEqual(XCTUnwrap(addAttributes[kSecClass] as? String), String(kSecClassGenericPassword))
    }

    /// `setValue(_:for:)` updates an existing item without calling add.
    ///
    func test_setValue_updatesExistingItem() async throws {
        let newKey = "test-value"
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            item.accessControlFlags ?? [],
            nil,
        )!

        keychainService.accessControlResult = .success(accessControl)
        keychainService.updateResult = .success(())

        try await subject.setValue(newKey, for: item)

        // Verify update was called with correct query and attributes
        let updateQuery = try XCTUnwrap(keychainService.updateQuery as? [CFString: Any])
        let expectedFormattedKey = await subject.formattedKey(for: item)
        try XCTAssertEqual(XCTUnwrap(updateQuery[kSecAttrAccount] as? String), expectedFormattedKey)
        try XCTAssertEqual(XCTUnwrap(updateQuery[kSecAttrAccessGroup] as? String), subject.appSecAttrAccessGroup)
        try XCTAssertEqual(XCTUnwrap(updateQuery[kSecAttrService] as? String), subject.appSecAttrService)
        try XCTAssertEqual(XCTUnwrap(updateQuery[kSecClass] as? String), String(kSecClassGenericPassword))
        XCTAssertNil(updateQuery[kSecValueData])
        XCTAssertNil(updateQuery[kSecAttrAccessControl])

        let updateAttributes = try XCTUnwrap(keychainService.updateAttributes as? [CFString: Any])
        XCTAssertNotNil(updateAttributes[kSecValueData])
        XCTAssertNotNil(updateAttributes[kSecAttrAccessControl])
        let valueData = try XCTUnwrap(updateAttributes[kSecValueData] as? Data)
        XCTAssertEqual(String(data: valueData, encoding: .utf8), newKey)
        XCTAssertEqual(updateAttributes.count, 2)

        // Verify add was NOT called
        XCTAssertNil(keychainService.addAttributes)
    }

    // MARK: Client Certificate Tests

    /// `deleteClientCertificateIdentity(fingerprint:)` deletes with the correct query attributes.
    func test_deleteClientCertificateIdentity_usesCorrectQuery() async throws {
        appIDSettingsStore.appID = "testAppID"
        let fingerprint = "abc123"
        let expectedLabel = await subject.formattedKey(
            for: .clientCertificateIdentity(fingerprint: fingerprint),
        )

        try await subject.deleteClientCertificateIdentity(fingerprint: fingerprint)

        let query = try XCTUnwrap(keychainService.deleteQueries.last as? [String: Any])
        XCTAssertEqual(query[kSecClass as String] as? String, String(kSecClassIdentity))
        XCTAssertEqual(query[kSecAttrLabel as String] as? String, expectedLabel)
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, subject.appSecAttrAccessGroup)
        XCTAssertEqual(query.count, 3)
    }

    /// `deleteClientCertificateIdentity(fingerprint:)` rethrows unexpected keychain errors.
    func test_deleteClientCertificateIdentity_throwsError_onDeleteFailure() async {
        keychainService.deleteResult = .failure(.osStatusError(-1))

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            try await subject.deleteClientCertificateIdentity(fingerprint: "abc123")
        }
    }

    /// `getClientCertificateIdentity(fingerprint:)` returns nil when the keychain search returns nil.
    func test_getClientCertificateIdentity_returnsNil_whenNotFound() async throws {
        keychainService.searchResult = .success(nil)

        let result = try await subject.getClientCertificateIdentity(fingerprint: "abc123")

        XCTAssertNil(result)
    }

    /// `getClientCertificateIdentity(fingerprint:)` returns nil when the item is not in the keychain.
    func test_getClientCertificateIdentity_returnsNil_whenItemNotFoundError() async throws {
        keychainService.searchResult = .failure(.osStatusError(errSecItemNotFound))

        let result = try await subject.getClientCertificateIdentity(fingerprint: "abc123")

        XCTAssertNil(result)
    }

    /// `getClientCertificateIdentity(fingerprint:)` rethrows unexpected keychain errors.
    func test_getClientCertificateIdentity_throwsError_onUnexpectedSearchError() async {
        keychainService.searchResult = .failure(.osStatusError(-1))

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            _ = try await subject.getClientCertificateIdentity(fingerprint: "abc123")
        }
    }

    /// `getClientCertificateIdentity(fingerprint:)` searches with the correct query attributes.
    func test_getClientCertificateIdentity_usesCorrectQuery() async throws {
        appIDSettingsStore.appID = "testAppID"
        keychainService.searchResult = .success(nil)
        let fingerprint = "abc123"
        let expectedLabel = await subject.formattedKey(
            for: .clientCertificateIdentity(fingerprint: fingerprint),
        )

        _ = try await subject.getClientCertificateIdentity(fingerprint: fingerprint)

        let query = try XCTUnwrap(keychainService.searchQuery as? [String: Any])
        XCTAssertEqual(query[kSecClass as String] as? String, String(kSecClassIdentity))
        XCTAssertEqual(query[kSecAttrLabel as String] as? String, expectedLabel)
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, subject.appSecAttrAccessGroup)
        XCTAssertEqual(query[kSecReturnRef as String] as? Bool, true)
        XCTAssertEqual(query[kSecMatchLimit as String] as? String, String(kSecMatchLimitOne))
    }

    /// `getClientCertificateIdentity(fingerprint:)` returns the identity when one is stored.
    func test_getClientCertificateIdentity_returnsIdentity_whenPresent() async throws {
        let identity = try makeTestIdentity()
        keychainService.searchResult = .success(identity)

        let result = try await subject.getClientCertificateIdentity(fingerprint: "abc123")

        XCTAssertNotNil(result)
    }

    /// `setClientCertificateIdentity(_:fingerprint:)` adds the identity with the correct attributes.
    func test_setClientCertificateIdentity_addsWithCorrectAttributes() async throws {
        appIDSettingsStore.appID = "testAppID"
        let fingerprint = "abc123"
        let identity = try makeTestIdentity()
        let expectedLabel = await subject.formattedKey(
            for: .clientCertificateIdentity(fingerprint: fingerprint),
        )

        try await subject.setClientCertificateIdentity(identity, fingerprint: fingerprint)

        let addAttributes = try XCTUnwrap(keychainService.addAttributes as? [String: Any])
        XCTAssertEqual(addAttributes[kSecClass as String] as? String, String(kSecClassIdentity))
        XCTAssertEqual(addAttributes[kSecAttrLabel as String] as? String, expectedLabel)
        XCTAssertEqual(addAttributes[kSecAttrAccessGroup as String] as? String, subject.appSecAttrAccessGroup)
        XCTAssertEqual(
            addAttributes[kSecAttrAccessible as String] as? String,
            String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly),
        )
        XCTAssertNotNil(addAttributes[kSecValueRef as String])
    }

    /// `setClientCertificateIdentity(_:fingerprint:)` rethrows errors from the keychain service.
    func test_setClientCertificateIdentity_throwsError_onAddFailure() async throws {
        keychainService.addResult = .failure(.osStatusError(-1))
        let identity = try makeTestIdentity()

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            try await subject.setClientCertificateIdentity(identity, fingerprint: "abc123")
        }
    }

    // MARK: Private

    /// Creates a `SecIdentity` from a pre-generated self-signed test PKCS#12 (password: "testpassword").
    private func makeTestIdentity() throws -> SecIdentity {
        // swiftlint:disable:next line_length
        let p12Base64 = "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"
        let p12Data = try XCTUnwrap(Data(base64Encoded: p12Base64))
        var importResult: CFArray?
        let status = SecPKCS12Import(
            p12Data as CFData,
            [kSecImportExportPassphrase: "testpassword"] as CFDictionary,
            &importResult,
        )
        guard status == errSecSuccess,
              let items = importResult as? [[String: Any]],
              let identityRef = items.first?[kSecImportItemIdentity as String] else {
            throw XCTestError(
                .failureWhileWaiting,
                userInfo: [NSLocalizedDescriptionKey: "Failed to import test identity"],
            )
        }
        // swiftlint:disable:next force_cast
        return identityRef as! SecIdentity
    }
}
