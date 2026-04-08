import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

// MARK: - KeychainRepositoryTests

final class KeychainRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var keychainService: MockKeychainService!
    var keychainServiceFacade: MockKeychainServiceFacade!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        keychainService = MockKeychainService()
        keychainServiceFacade = MockKeychainServiceFacade()
        subject = DefaultKeychainRepository(
            keychainService: keychainService,
            keychainServiceFacade: keychainServiceFacade,
        )
    }

    override func tearDown() {
        super.tearDown()

        keychainService = nil
        keychainServiceFacade = nil
        subject = nil
    }

    // MARK: Tests - deleteAllItems

    /// `deleteAllItems` deletes items for all classes via the raw keychain service.
    ///
    func test_deleteAllItems() async throws {
        var deletedQueries: [CFDictionary] = []
        keychainService.deleteClosure = { query in
            deletedQueries.append(query)
        }

        try await subject.deleteAllItems()

        XCTAssertEqual(
            deletedQueries,
            [
                [kSecClass: kSecClassGenericPassword] as CFDictionary,
                [kSecClass: kSecClassInternetPassword] as CFDictionary,
                [kSecClass: kSecClassCertificate] as CFDictionary,
                [kSecClass: kSecClassKey] as CFDictionary,
                [kSecClass: kSecClassIdentity] as CFDictionary,
            ],
        )
    }

    // MARK: Tests - deleteAuthenticatorVaultKey(userId:)

    /// `deleteAuthenticatorVaultKey(userId:)` deletes the correct item via the facade.
    ///
    func test_deleteAuthenticatorVaultKey_success() async throws {
        try await subject.deleteAuthenticatorVaultKey(userId: "1")

        XCTAssertEqual(
            keychainServiceFacade.deleteValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.authenticatorVaultKey(userId: "1").unformattedKey,
        )
    }

    // MARK: Tests - deleteItems(for:)

    /// `deleteItems(for:)` deletes the expected items via the facade in order.
    ///
    func test_deleteItems_forUserId() async throws {
        var deletedKeys: [String] = []
        keychainServiceFacade.deleteValueClosure = { item in
            deletedKeys.append(item.unformattedKey)
        }

        try await subject.deleteItems(for: "1")

        XCTAssertEqual(
            deletedKeys,
            [
                BitwardenKeychainItem.accessToken(userId: "1").unformattedKey,
                BitwardenKeychainItem.authenticatorVaultKey(userId: "1").unformattedKey,
                BitwardenKeychainItem.biometrics(userId: "1").unformattedKey,
                BitwardenKeychainItem.lastActiveTime(userId: "1").unformattedKey,
                BitwardenKeychainItem.neverLock(userId: "1").unformattedKey,
                BitwardenKeychainItem.refreshToken(userId: "1").unformattedKey,
                BitwardenKeychainItem.unsuccessfulUnlockAttempts(userId: "1").unformattedKey,
            ],
        )
    }

    // MARK: Tests - deleteDeviceKey(userId:)

    /// `deleteDeviceKey(userId:)` deletes the correct item via the facade.
    ///
    func test_deleteDeviceKey_success() async throws {
        try await subject.deleteDeviceKey(userId: "1")

        XCTAssertEqual(
            keychainServiceFacade.deleteValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.deviceKey(userId: "1").unformattedKey,
        )
    }

    // MARK: Tests - deletePendingAdminLoginRequest(userId:)

    /// `deletePendingAdminLoginRequest(userId:)` deletes the correct item via the facade.
    ///
    func test_deletePendingAdminLoginRequest_success() async throws {
        try await subject.deletePendingAdminLoginRequest(userId: "1")

        XCTAssertEqual(
            keychainServiceFacade.deleteValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.pendingAdminLoginRequest(userId: "1").unformattedKey,
        )
    }

    // MARK: Tests - deleteUserAuthKey(for:)

    /// `deleteUserAuthKey(for:)` deletes the item via the facade.
    ///
    func test_deleteUserAuthKey_success() async throws {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        try await subject.deleteUserAuthKey(for: item)

        XCTAssertEqual(keychainServiceFacade.deleteValueReceivedItem?.unformattedKey, item.unformattedKey)
    }

    /// `deleteUserAuthKey(for:)` rethrows errors from the facade.
    ///
    func test_deleteUserAuthKey_rethrows() async {
        keychainServiceFacade.deleteValueThrowableError = KeychainServiceError.osStatusError(-1)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            try await subject.deleteUserAuthKey(for: .biometrics(userId: "123"))
        }
    }

    // MARK: Tests - getAccessToken(userId:)

    /// `getAccessToken(userId:)` returns the stored access token.
    ///
    func test_getAccessToken() async throws {
        keychainServiceFacade.getValueReturnValue = "ACCESS_TOKEN"

        let result = try await subject.getAccessToken(userId: "1")

        XCTAssertEqual(result, "ACCESS_TOKEN")
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.accessToken(userId: "1").unformattedKey,
        )
    }

    /// `getAccessToken(userId:)` rethrows errors from the facade.
    ///
    func test_getAccessToken_error() async {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.accessToken(userId: "1"))
        keychainServiceFacade.getValueThrowableError = error

        await assertAsyncThrows(error: error) {
            _ = try await subject.getAccessToken(userId: "1")
        }
    }

    // MARK: Tests - getAuthenticatorVaultKey(userId:)

    /// `getAuthenticatorVaultKey(userId:)` returns the stored authenticator vault key.
    ///
    func test_getAuthenticatorVaultKey() async throws {
        keychainServiceFacade.getValueReturnValue = "AUTHENTICATOR_VAULT_KEY"

        let result = try await subject.getAuthenticatorVaultKey(userId: "1")

        XCTAssertEqual(result, "AUTHENTICATOR_VAULT_KEY")
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.authenticatorVaultKey(userId: "1").unformattedKey,
        )
    }

    /// `getAuthenticatorVaultKey(userId:)` rethrows errors from the facade.
    ///
    func test_getAuthenticatorVaultKey_error() async {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.authenticatorVaultKey(userId: "1"))
        keychainServiceFacade.getValueThrowableError = error

        await assertAsyncThrows(error: error) {
            _ = try await subject.getAuthenticatorVaultKey(userId: "1")
        }
    }

    // MARK: Tests - getDeviceKey(userId:)

    /// `getDeviceKey(userId:)` returns the stored device key.
    ///
    func test_getDeviceKey() async throws {
        keychainServiceFacade.getValueReturnValue = "DEVICE_KEY"

        let result = try await subject.getDeviceKey(userId: "1")

        XCTAssertEqual(result, "DEVICE_KEY")
    }

    /// `getDeviceKey(userId:)` rethrows non-notFound errors.
    ///
    func test_getDeviceKey_error() async {
        let error = KeychainServiceError.osStatusError(-1)
        keychainServiceFacade.getValueThrowableError = error

        await assertAsyncThrows(error: error) {
            _ = try await subject.getDeviceKey(userId: "1")
        }
    }

    /// `getDeviceKey(userId:)` returns nil on keyNotFound.
    ///
    func test_getDeviceKey_notFound() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.deviceKey(userId: "1")
        )

        let result = try await subject.getDeviceKey(userId: "1")

        XCTAssertNil(result)
    }

    // MARK: Tests - getRefreshToken(userId:)

    /// `getRefreshToken(userId:)` returns the stored refresh token.
    ///
    func test_getRefreshToken() async throws {
        keychainServiceFacade.getValueReturnValue = "REFRESH_TOKEN"

        let result = try await subject.getRefreshToken(userId: "1")

        XCTAssertEqual(result, "REFRESH_TOKEN")
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.refreshToken(userId: "1").unformattedKey,
        )
    }

    /// `getRefreshToken(userId:)` rethrows errors from the facade.
    ///
    func test_getRefreshToken_error() async {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.refreshToken(userId: "1"))
        keychainServiceFacade.getValueThrowableError = error

        await assertAsyncThrows(error: error) {
            _ = try await subject.getRefreshToken(userId: "1")
        }
    }

    // MARK: Tests - getPendingAdminLoginRequest(userId:)

    /// `getPendingAdminLoginRequest(userId:)` returns the stored pending admin login request.
    ///
    func test_getPendingAdminLoginRequest() async throws {
        keychainServiceFacade.getValueReturnValue = "PENDING_ADMIN_LOGIN_REQUEST"

        let result = try await subject.getPendingAdminLoginRequest(userId: "1")

        XCTAssertEqual(result, "PENDING_ADMIN_LOGIN_REQUEST")
    }

    /// `getPendingAdminLoginRequest(userId:)` rethrows non-notFound errors.
    ///
    func test_getPendingAdminLoginRequest_error() async {
        let error = KeychainServiceError.osStatusError(-1)
        keychainServiceFacade.getValueThrowableError = error

        await assertAsyncThrows(error: error) {
            _ = try await subject.getPendingAdminLoginRequest(userId: "1")
        }
    }

    /// `getPendingAdminLoginRequest(userId:)` returns nil on keyNotFound.
    ///
    func test_getPendingAdminLoginRequest_notFound() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.pendingAdminLoginRequest(userId: "1")
        )

        let result = try await subject.getPendingAdminLoginRequest(userId: "1")

        XCTAssertNil(result)
    }

    // MARK: Tests - getUserAuthKeyValue(for:)

    /// `getUserAuthKeyValue(for:)` returns the value from the facade.
    ///
    func test_getUserAuthKeyValue_success() async throws {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        keychainServiceFacade.getValueReturnValue = "1234"

        let result = try await subject.getUserAuthKeyValue(for: item)

        XCTAssertEqual(result, "1234")
        XCTAssertEqual(keychainServiceFacade.getValueReceivedItem?.unformattedKey, item.unformattedKey)
    }

    /// `getUserAuthKeyValue(for:)` rethrows errors from the facade.
    ///
    func test_getUserAuthKeyValue_error() async {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.osStatusError(-1)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            _ = try await subject.getUserAuthKeyValue(for: item)
        }
    }

    // MARK: Tests - setAccessToken(_:userId:)

    /// `setAccessToken(_:userId:)` stores the value via the facade for the correct item.
    ///
    func test_setAccessToken() async throws {
        try await subject.setAccessToken("ACCESS_TOKEN", userId: "1")

        XCTAssertEqual(keychainServiceFacade.setValueReceivedArguments?.value, "ACCESS_TOKEN")
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            BitwardenKeychainItem.accessToken(userId: "1").unformattedKey,
        )
    }

    /// `setAccessToken(_:userId:)` rethrows errors from the facade.
    ///
    func test_setAccessToken_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainServiceFacade.setValueThrowableError = error

        await assertAsyncThrows(error: error) {
            try await subject.setAccessToken("ACCESS_TOKEN", userId: "1")
        }
    }

    // MARK: Tests - setAuthenticatorVaultKey(_:userId:)

    /// `setAuthenticatorVaultKey(_:userId:)` stores the value via the facade for the correct item.
    ///
    func test_setAuthenticatorVaultKey() async throws {
        try await subject.setAuthenticatorVaultKey("AUTHENTICATOR_VAULT_KEY", userId: "1")

        XCTAssertEqual(keychainServiceFacade.setValueReceivedArguments?.value, "AUTHENTICATOR_VAULT_KEY")
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            BitwardenKeychainItem.authenticatorVaultKey(userId: "1").unformattedKey,
        )
    }

    /// `setAuthenticatorVaultKey(_:userId:)` rethrows errors from the facade.
    ///
    func test_setAuthenticatorVaultKey_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainServiceFacade.setValueThrowableError = error

        await assertAsyncThrows(error: error) {
            try await subject.setAuthenticatorVaultKey("AUTHENTICATOR_VAULT_KEY", userId: "1")
        }
    }

    // MARK: Tests - setRefreshToken(_:userId:)

    /// `setRefreshToken(_:userId:)` stores the value via the facade for the correct item.
    ///
    func test_setRefreshToken() async throws {
        try await subject.setRefreshToken("REFRESH_TOKEN", userId: "1")

        XCTAssertEqual(keychainServiceFacade.setValueReceivedArguments?.value, "REFRESH_TOKEN")
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            BitwardenKeychainItem.refreshToken(userId: "1").unformattedKey,
        )
    }

    /// `setRefreshToken(_:userId:)` rethrows errors from the facade.
    ///
    func test_setRefreshToken_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainServiceFacade.setValueThrowableError = error

        await assertAsyncThrows(error: error) {
            try await subject.setRefreshToken("REFRESH_TOKEN", userId: "1")
        }
    }

    // MARK: Tests - setUserAuthKey(for:value:)

    /// `setUserAuthKey(for:value:)` stores the value via the facade for the given item.
    ///
    func test_setUserAuthKey_success() async throws {
        let item = BitwardenKeychainItem.biometrics(userId: "123")
        try await subject.setUserAuthKey(for: item, value: "123")

        XCTAssertEqual(keychainServiceFacade.setValueReceivedArguments?.value, "123")
        XCTAssertEqual(keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey, item.unformattedKey)
    }

    /// `setUserAuthKey(for:value:)` rethrows errors from the facade.
    ///
    func test_setUserAuthKey_error() async {
        keychainServiceFacade.setValueThrowableError = KeychainServiceError.osStatusError(-1)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            try await subject.setUserAuthKey(for: .biometrics(userId: "123"), value: "123")
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
        let p12Base64 = "MIIJ5wIBAzCCCZUGCSqGSIb3DQEHAaCCCYYEggmCMIIJfjCCA+oGCSqGSIb3DQEHBqCCA9swggPXAgEAMIID0AYJKoZIhvcNAQcBMF8GCSqGSIb3DQEFDTBSMDEGCSqGSIb3DQEFDDAkBBC86VrMILQn/82wIGDcfN8bAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQh1Zv8tfgk1ZzNpAaNMMYP4CCA2BmvyOLey4561vYT+ZNOEtz95GyymQBcRxPGqS81ei30LtkX14Vqfw6yYwojpzSSUgwSw6IId/AdXfx0zQDho6mVnHZiCIGdzJ3DXcPQxud9/fJRnT56CSZFCe2Udlrkx+9W7mHoeg1ZgMPVna6nx9c62vUjcyzoFsGM/Bq4Zc2lzCSRxjH4b/2BjNkOG55aNrEFVS3iqEkNVxeQKNbonSbdzCaBXL+fpY8n+j9kUpIvHriq+hxc2XDQwAlNNVOs146Vl/pFa2SbtOAbchNDUQl0YGbnilciMP7n4pFbR6HyLKKma6eRhKJimo+vVeTkkkTlbxXu14owc5Y2jocL3DiBegDRWzvoDPLXGMAqatcJ91EKAkmYAQM0TjLSowhwW2+0J1EG4OwM5I7/YgXo6k8RK1+BFIEtscHGcZ1s1TOpwMaqVtWdNNNmCXiiccIOT4W+KqKJaJmQN/+oyPz7xzuHRzfrDAIkyp5fUrJ7BY+VzZ2oQ3Q79m21pcYPdyihNaeMcBP/gPpY1P60cwVDqo/FW+qBxwySjVkCpq88/GkkjfgSrQKx/wFdTWaFUapuRQvxx7NEaXvkUlVmmkXOJ+QLlDtJ5J/TEJmpk9Ui/G+nz3XvlvJcQQCEqc2kA5wsGIb0ePg+cXT+mckLHD0bMvRZIWbWpdLblU0I+Q1kDh4KBP5FEL9ibZ8NwOcD7hzwbO4M9i10V74n+yD63aupnd+Bui7Ti82mokyxRB9kPGwFNA48d1NrCjOR8/LUxYfkU1mdkmdLJ1cotZAY5+ePyPh6A/20RwfTZKkGqYQ7Jeq5B7xme1hCT5M9kbTt6F3J3jpwAtcxUk1FasbOVeIZYZoauexJOJ7f1MSe5kNKCDPA1lszvP/bT3C4l7eZQ7AlQ4Xrp2uZyrtDruBF8zrLveWebu0ZNA0KG47i/J0RNdHoQGS168Yqhsg0tkTu9wRhFkY3hRxMrZCoI5SoXPL9otG7XMaLqZT/k7Ahe80QweVVfgZynbW1OGwaaPizh+ZiinEN8Eo5u/r9kwPut/7ehYr82kns1ARRxsLMFcRRxcoue56dxIcstw6wWq2qTRK9elv3nZ+tar1TZLkFthBPFZ72g1YXGYdA47HXQ9bwlRaPQzIL9UWxyUwRtYJbPCPTs0wggWMBgkqhkiG9w0BBwGgggV9BIIFeTCCBXUwggVxBgsqhkiG9w0BDAoBAqCCBTkwggU1MF8GCSqGSIb3DQEFDTBSMDEGCSqGSIb3DQEFDDAkBBCBth0cXBbXixtpEjUEoLs0AgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQ5DWBC/j8jCua7zXT28a4YwSCBNAJiodUw7ZxxK13bv+LBfBnPsk6dcS3GiewMEKNgCAVhYgaDiF1qt05JnG+zCkzKbeRGBE45MlOek+c6/vNsH3jYktxn6gpeakSDe8zq3RBnwHsnycrlx7WPe+76rgAGOK+NwJ/6wwrxZeG0mw1DCOy9cJaFM8ssAXDEnsjc0FWqjcdnOUwODmfP0R+HIA6FN+4taTZM7fuuTxtMo3DBJZRosr94gEoRBd8MyOvoMhM8AWa8ypDvbK6yBITP/pFQXS5dXC7zB1EWNtBwyBn2YjMDzFOYeew4FfkTnvpHKyM8N9IoM1Mmv2m7IPz3QLbMSC7FRTkoDo5Qx2K3QugbSb916DwrzG/Idm2libgGnZU1ER7o12WDZbQlIKs5+7CANk3gTaW0KBCjStDQfVtTUd8CoyprQn1C2jnIEFyDX5LP7jG8K8JwIBo263GoEKcusGToy5iNC0qhmRtFxx8L1zqxwlMxfpliEuXgpsRbpUWKeOban39PTEjd73AWoi9rEt1IF1+d1qAxolSldLfmZT/IWWe9KhtUU3qMI9M8E6oPMaMtaaX+Ey0yYossVPRH0I6JGwySxk/sdeY1BaI+qFQr5n5RzSyWfrsLtuMriVyf1xwXdOv4w+eanmCfXlWstVHo06TLiCegi5sG9YnJ753RSoKUx5lm/dwsuUnD89mhD5l507LxkMT/YQMyp1u2Js4gdCPRCCwat+fyRR7SHI94p2axD9vj2siqC1fWUwSxIHiYRrO4CJmEuPhUCti+1QeckQ2NvCt5+yeVDbTzNMemqzchfkLWB9vv+YviaCYFQnQrqW6jjn8xugRnyhAE82cuknUSKRDaQCpfQrHj2jJTVIdksAXAIWgR85O6eg5DSLjqFlFWz0DjVeixNXnnTDTpfzzSSoHn/RWsBPS55W5JDIcowP240IQYoJlEo6yOE6mum1WyycnLyvmpHy2KALHYTpgC7peaubpUPdHqEzKh4rB74fM+LWEV24VSIqyZSU15zYLtKOR/RFoo7ax/o8wfw4BIBScfkLBnwWajX6TU/bk+dsWEs7Rbx+gnvmfI2K1QC4VO+rGLfx25Ko49Xm05HFyOgJ4sjg7wVZWCfeZjrhFItQbC8l7SniaPPhCNmhXDA7m8vRjyuhRNzoA0cfwOWP4LHRJMkx3adiQ/0fgfvq6M33M7GaXoXkRQNZmArqatBwIMuSUsDhmYV9Hj+4b4aaij2sONOkJ12uhvPH5lbFkW/G7soX4mDmVqNNQ29OBkghyxEPEEUjKsnYFTee84ioR++qFG3JmRZl7KtqbCTb/0SZ5+24acBw9nAND7ZEuqgTNzMkTeNcrAxJQc59hYNYUVEMmWc5xepSEplSyT4sZ6p/CcLtVLzcE1y0/uwS6ME1TeOKypN8hDL5svrKqPJVY0RPjbwo5KIB/Z0R4F3hknq7X9pWmbWI58EVYMbBS8LoyTMnzS/RQJ4GH9AmdcnUsVc1FZpqr0y/47MOhtemMkjSfJGNpn6fkw49ceZYzrL7dWny0/pmMj5v80aRaSkK6/9L9dVsR+S/JXAUoMUbSwOOrHUnZnV4xvqfl5BDWQQ68Tb/+JcGJvpz8/jSL5Py9ufTJb1icrGT6Tikw2cGOJiXx9MKjENUQ/K2nFDElMCMGCSqGSIb3DQEJFTEWBBRHKaAOUTtQo8+EpzxFM2lajGKlHzBJMDEwDQYJYIZIAWUDBAIBBQAEICg82PwhdNWsdx+7UvjSH4HsFcGAWYMeIj8BNyFYxMNlBBAwM1m3obPZ/LJ2BIySceujAgIIAA=="
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
