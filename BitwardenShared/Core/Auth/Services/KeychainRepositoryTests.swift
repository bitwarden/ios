import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

// MARK: - KeychainRepositoryTests

final class KeychainRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var keychainService: MockKeychainService!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        keychainService = MockKeychainService()
        subject = DefaultKeychainRepository(
            appIdService: AppIdService(
                appSettingStore: appSettingsStore
            ),
            keychainService: keychainService
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        keychainService = nil
        subject = nil
    }

    // MARK: Tests

    /// The service provides a kSecAttrService value.
    ///
    func test_appSecAttrService() {
        XCTAssertEqual(
            Bundle.main.appIdentifier,
            subject.appSecAttrService
        )
    }

    /// The service provides a kSecAttrAccessGroup value.
    ///
    func test_appSecAttrAccessGroup() {
        XCTAssertEqual(
            Bundle.main.keychainAccessGroup,
            subject.appSecAttrAccessGroup
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
        let item = KeychainItem.biometrics(userId: "123")
        keychainService.deleteResult = .success(())
        let expectedQuery = await subject.keychainQueryValues(for: item)

        try await subject.deleteUserAuthKey(for: item)
        XCTAssertEqual(
            keychainService.deleteQueries,
            [expectedQuery]
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
            ]
        )
    }

    /// `deleteItems(for:)` deletes items for a specific user.
    func test_deleteItems_forUserId() async throws {
        try await subject.deleteItems(for: "1")

        let expectedQueries = await [
            subject.keychainQueryValues(for: .accessToken(userId: "1")),
            subject.keychainQueryValues(for: .authenticatorVaultKey(userId: "1")),
            subject.keychainQueryValues(for: .biometrics(userId: "1")),
            subject.keychainQueryValues(for: .neverLock(userId: "1")),
            subject.keychainQueryValues(for: .pendingAdminLoginRequest(userId: "1")),
            subject.keychainQueryValues(for: .refreshToken(userId: "1")),
        ]

        XCTAssertEqual(
            keychainService.deleteQueries,
            expectedQueries
        )
    }

    /// `deleteDeviceKey` succeeds quietly.
    ///
    func test_deleteDeviceKey_success() async throws {
        let item = KeychainItem.deviceKey(userId: "1")
        keychainService.deleteResult = .success(())
        let expectedQuery = await subject.keychainQueryValues(for: item)

        try await subject.deleteDeviceKey(userId: "1")
        XCTAssertEqual(
            keychainService.deleteQueries,
            [expectedQuery]
        )
    }

    /// `deleteAuthenticatorVaultKey` deletes the stored Authenticator Vault Key with the correct query values.
    ///
    func test_deleteAuthenticatorVaultKey_success() async throws {
        let item = KeychainItem.authenticatorVaultKey(userId: "1")
        keychainService.deleteResult = .success(())
        let expectedQuery = await subject.keychainQueryValues(for: item)

        try await subject.deleteAuthenticatorVaultKey(userId: "1")
        XCTAssertEqual(
            keychainService.deleteQueries,
            [expectedQuery]
        )
    }

    /// The service should generate a storage key for a` KeychainItem`.
    ///
    func test_formattedKey_biometrics() async {
        let item = KeychainItem.biometrics(userId: "123")
        appSettingsStore.appId = "testAppId"
        let formattedKey = await subject.formattedKey(for: item)
        let expectedKey = String(format: subject.storageKeyFormat, "testAppId", item.unformattedKey)

        XCTAssertEqual(
            formattedKey,
            expectedKey
        )
    }

    /// The service should generate a storage key for a` KeychainItem`.
    ///
    func test_formattedKey_neverLock() async {
        let item = KeychainItem.neverLock(userId: "123")
        appSettingsStore.appId = "testAppId"
        let formattedKey = await subject.formattedKey(for: item)
        let expectedKey = String(format: subject.storageKeyFormat, "testAppId", item.unformattedKey)

        XCTAssertEqual(
            formattedKey,
            expectedKey
        )
    }

    /// `getAuthenticatorVaultKey(userId:)` returns the stored authenticator vault key.
    func test_getAuthenticatorVaultKey() async throws {
        keychainService.setSearchResultData(string: "AUTHENTICATOR_VAULT_KEY")
        let authVaultKey = try await subject.getAuthenticatorVaultKey(userId: "1")
        XCTAssertEqual(authVaultKey, "AUTHENTICATOR_VAULT_KEY")
    }

    /// `getAuthenticatorVaultKey(userId:)` throws an error if one occurs.
    func test_getAuthenticatorVaultKey_error() async {
        let error = KeychainServiceError.keyNotFound(.authenticatorVaultKey(userId: "1"))
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getAuthenticatorVaultKey(userId: "1")
        }
    }

    /// `getAccessToken(userId:)` returns the stored access token.
    func test_getAccessToken() async throws {
        keychainService.setSearchResultData(string: "ACCESS_TOKEN")
        let accessToken = try await subject.getAccessToken(userId: "1")
        XCTAssertEqual(accessToken, "ACCESS_TOKEN")
    }

    /// `getAccessToken(userId:)` throws an error if one occurs.
    func test_getAccessToken_error() async {
        let error = KeychainServiceError.keyNotFound(.accessToken(userId: "1"))
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getAccessToken(userId: "1")
        }
    }

    /// `getRefreshToken(userId:)` returns the stored refresh token.
    func test_getRefreshToken() async throws {
        keychainService.setSearchResultData(string: "REFRESH_TOKEN")
        let accessToken = try await subject.getRefreshToken(userId: "1")
        XCTAssertEqual(accessToken, "REFRESH_TOKEN")
    }

    /// `getRefreshToken(userId:)` throws an error if one occurs.
    func test_getRefreshToken_error() async {
        let error = KeychainServiceError.keyNotFound(.refreshToken(userId: "1"))
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getRefreshToken(userId: "1")
        }
    }

    /// `getUserAuthKeyValue(_:)` failures rethrow.
    ///
    func test_getUserAuthKeyValue_error_searchError() async {
        let item = KeychainItem.biometrics(userId: "123")
        let searchError = KeychainServiceError.osStatusError(-1)
        keychainService.searchResult = .failure(searchError)
        await assertAsyncThrows(error: searchError) {
            _ = try await subject.getUserAuthKeyValue(for: item)
        }
    }

    /// `getUserAuthKeyValue(_:)` errors if the search results are not in the correct format.
    ///
    func test_getUserAuthKeyValue_error_malformedData() async {
        let item = KeychainItem.biometrics(userId: "123")
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
        let item = KeychainItem.biometrics(userId: "123")
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
        let item = KeychainItem.biometrics(userId: "123")
        let notFoundError = KeychainServiceError.keyNotFound(item)
        keychainService.searchResult = .success(nil)
        await assertAsyncThrows(error: notFoundError) {
            _ = try await subject.getUserAuthKeyValue(for: .biometrics(userId: "123"))
        }
    }

    /// `getUserAuthKeyValue(_:)` returns a string on success.
    ///
    func test_getUserAuthKeyValue_error_success() async throws {
        let item = KeychainItem.biometrics(userId: "123")
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
        let item = KeychainItem.biometrics(userId: "123")
        appSettingsStore.appId = "testAppId"
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
            expectedResult
        )
    }

    /// The service should generate keychain Query Key/Values` KeychainItem`.
    ///
    func test_keychainQueryValues_neverLock() async {
        let item = KeychainItem.neverLock(userId: "123")
        appSettingsStore.appId = "testAppId"
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
            expectedResult
        )
    }

    /// `setAuthenticatorVaultKey(userId:)` stores the authenticator vault key.
    func test_setAuthenticatorVaultKey() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [],
                nil
            )!
        )
        keychainService.setSearchResultData(string: "AUTHENTICATOR_VAULT_KEY")
        try await subject.setAuthenticatorVaultKey("AUTHENTICATOR_VAULT_KEY", userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        try XCTAssertEqual(
            String(data: XCTUnwrap(attributes[kSecValueData] as? Data), encoding: .utf8),
            "AUTHENTICATOR_VAULT_KEY"
        )
    }

    /// `setAuthenticatorVaultKey(userId:)` throws an error if one occurs.
    func test_setAuthenticatorVaultKey_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainService.addResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.setAuthenticatorVaultKey("AUTHENTICATOR_VAULT_KEY", userId: "1")
        }
    }

    /// `setAccessToken(userId:)` stored the access token.
    func test_setAccessToken() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [],
                nil
            )!
        )
        keychainService.setSearchResultData(string: "ACCESS_TOKEN")
        try await subject.setAccessToken("ACCESS_TOKEN", userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        try XCTAssertEqual(
            String(data: XCTUnwrap(attributes[kSecValueData] as? Data), encoding: .utf8),
            "ACCESS_TOKEN"
        )
    }

    /// `setAccessToken(userId:)` throws an error if one occurs.
    func test_setAccessToken_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainService.addResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.setAccessToken("ACCESS_TOKEN", userId: "1")
        }
    }

    /// `setRefreshToken(userId:)` stored the refresh token.
    func test_setRefreshToken() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [],
                nil
            )!
        )
        keychainService.setSearchResultData(string: "REFRESH_TOKEN")
        try await subject.setRefreshToken("REFRESH_TOKEN", userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        try XCTAssertEqual(
            String(data: XCTUnwrap(attributes[kSecValueData] as? Data), encoding: .utf8),
            "REFRESH_TOKEN"
        )
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
        let item = KeychainItem.biometrics(userId: "123")
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
        let item = KeychainItem.biometrics(userId: "123")
        let addError = KeychainServiceError.osStatusError(-1)
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                item.protection ?? [],
                nil
            )!
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
        let item = KeychainItem.biometrics(userId: "123")
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                item.protection ?? [],
                nil
            )!
        )
        keychainService.addResult = .success(())
        try await subject.setUserAuthKey(for: item, value: newKey)
        XCTAssertEqual(keychainService.accessControlFlags, .biometryCurrentSet)
    }

    /// `setUserAuthKey(_:)` succeeds quietly.
    ///
    func test_setUserAuthKey_success_neverlock() async throws {
        let newKey = "123"
        let item = KeychainItem.neverLock(userId: "123")
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                item.protection ?? [],
                nil
            )!
        )
        keychainService.addResult = .success(())
        try await subject.setUserAuthKey(for: item, value: newKey)
        XCTAssertEqual(keychainService.accessControlFlags, [])
    }
}
