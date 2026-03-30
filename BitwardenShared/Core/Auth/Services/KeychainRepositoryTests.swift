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
//    func test_deleteAllItems() async throws {
//        try await subject.deleteAllItems()
//
//        XCTAssertEqual(
//            keychainService.deleteQueries,
//            [
//                [kSecClass: kSecClassGenericPassword] as CFDictionary,
//                [kSecClass: kSecClassInternetPassword] as CFDictionary,
//                [kSecClass: kSecClassCertificate] as CFDictionary,
//                [kSecClass: kSecClassKey] as CFDictionary,
//                [kSecClass: kSecClassIdentity] as CFDictionary,
//            ],
//        )
//    }

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
}
