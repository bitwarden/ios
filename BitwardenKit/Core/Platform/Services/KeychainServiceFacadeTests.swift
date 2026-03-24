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
}
