import XCTest

@testable import BitwardenShared

// MARK: - KeychainRepositoryTests

final class KeychainRepositoryTests: BitwardenTestCase {
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
            Bundle.main.groupIdentifier,
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
            keychainService.deleteQuery,
            expectedQuery
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

    /// `getUserAuthKeyValue(_:)` failures rethrow.
    ///
    func test_getUserAuthKeyValue_error_searchError() async {
        let item = KeychainItem.biometrics(userId: "123")
        let searchError = KeychainServiceError.osStatusError(-1)
        keychainService.searchResult = .failure(searchError)
        await assertAsyncThrows(error: searchError) {
            _ = try await subject.getUserAuthKeyValue(for: .biometrics(userId: "123"))
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
        let notFoundError = KeychainServiceError.keyNotFound(item)
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

    /// `setUserAuthKey(_:)` failures rethrow.
    ///
    func test_setUserAuthKey_error_accessControl() async {
        let newKey = "123"
        let item = KeychainItem.biometrics(userId: "123")
        let accessError = KeychainServiceError.accessControlFailed(nil)
        keychainService.accessControlResult = .failure(accessError)
        keychainService.addResult = .success(())
        await assertAsyncThrows(error: accessError) {
            _ = try await subject.setUserAuthKey(for: .biometrics(userId: "123"), value: newKey)
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
