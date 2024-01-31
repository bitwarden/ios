import XCTest

@testable import BitwardenShared

// MARK: - KeychainRepositoryTests

final class KeychainRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        subject = DefaultKeychainRepository(
            appIdService: AppIdService(
                appSettingStore: appSettingsStore
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
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
}
