import AuthenticatorBridgeKit
import AuthenticatorBridgeKitMocks
import CryptoKit
import Foundation
import XCTest

final class SharedKeychainStorageTests: BitwardenTestCase {
    // MARK: Properties

    let accessGroup = "group.com.example.bitwarden"
    var keychainService: MockSharedKeychainService!
    var subject: SharedKeychainStorage!

    // MARK: Setup & Teardown

    override func setUp() {
        keychainService = MockSharedKeychainService()
        subject = DefaultSharedKeychainStorage(
            keychainService: keychainService,
            sharedAppGroupIdentifier: accessGroup,
        )
    }

    override func tearDown() {
        keychainService = nil
        subject = nil
    }

    // MARK: Tests

    /// Verify that `deleteValue(for:)` issues a delete with the correct search attributes specified.
    ///
    func test_deleteValue_success() async throws {
        try await subject.deleteValue(for: .authenticatorKey)

        let queries = try XCTUnwrap(keychainService.deleteQueries as? [[CFString: Any]])
        XCTAssertEqual(queries.count, 1)

        let query = try XCTUnwrap(queries.first)
        try XCTAssertEqual(XCTUnwrap(query[kSecAttrAccessGroup] as? String), accessGroup)
        try XCTAssertEqual(XCTUnwrap(query[kSecAttrAccessible] as? String),
                           String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly))
        try XCTAssertEqual(XCTUnwrap(query[kSecAttrAccount] as? String),
                           SharedKeychainItem.authenticatorKey.unformattedKey)
        try XCTAssertEqual(XCTUnwrap(query[kSecClass] as? String),
                           String(kSecClassGenericPassword))
    }

    /// Verify that `getValue(for:)` returns a value successfully when one is set. Additionally, verify the
    /// search attributes are specified correctly.
    ///
    func test_getValue_success() async throws {
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data(Array($0)) }
        let encodedData = try JSONEncoder.defaultEncoder.encode(data)

        keychainService.setSearchResultData(encodedData)

        let returnData: Data = try await subject.getValue(for: .authenticatorKey)
        XCTAssertEqual(returnData, data)

        let query = try XCTUnwrap(keychainService.searchQuery as? [CFString: Any])
        try XCTAssertEqual(XCTUnwrap(query[kSecAttrAccessGroup] as? String), accessGroup)
        try XCTAssertEqual(XCTUnwrap(query[kSecAttrAccessible] as? String),
                           String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly))
        try XCTAssertEqual(XCTUnwrap(query[kSecAttrAccount] as? String),
                           SharedKeychainItem.authenticatorKey.unformattedKey)
        try XCTAssertEqual(XCTUnwrap(query[kSecClass] as? String), String(kSecClassGenericPassword))
        try XCTAssertEqual(XCTUnwrap(query[kSecMatchLimit] as? String), String(kSecMatchLimitOne))
        try XCTAssertTrue(XCTUnwrap(query[kSecReturnAttributes] as? Bool))
        try XCTAssertTrue(XCTUnwrap(query[kSecReturnData] as? Bool))
    }

    /// Verify that `getAuthenticatorKey()` fails with a `keyNotFound` error when an unexpected
    /// result is returned instead of the key data from the keychain
    ///
    func test_getValue_badResult() async throws {
        let key = SharedKeychainItem.accountAutoLogout(userId: "1")
        let error = SharedKeychainServiceError.keyNotFound(key)
        keychainService.searchResult = .success([kSecValueData as String: NSObject()] as AnyObject)

        await assertAsyncThrows(error: error) {
            let _: Data = try await subject.getValue(for: key)
        }
    }

    /// Verify that `getValue(for:)` fails with a `keyNotFound` error when a nil
    /// result is returned instead of the key data from the keychain
    ///
    func test_getValue_nilResult() async throws {
        let key = SharedKeychainItem.accountAutoLogout(userId: "1")
        let error = SharedKeychainServiceError.keyNotFound(key)
        keychainService.searchResult = .success(nil)

        await assertAsyncThrows(error: error) {
            let _: Data = try await subject.getValue(for: key)
        }
    }

    /// Verify that `getValue(for:)` fails with an error when the Authenticator key is not
    /// present in the keychain
    ///
    func test_getAuthenticatorKey_keyNotFound() async throws {
        let error = SharedKeychainServiceError.keyNotFound(SharedKeychainItem.authenticatorKey)
        keychainService.searchResult = .failure(error)

        await assertAsyncThrows(error: error) {
            let _: Data = try await subject.getValue(for: .authenticatorKey)
        }
    }

    /// Verify that `setValue(_:for:)` sets a value with the correct search attributes specified.
    ///
    func test_setAuthenticatorKey_success() async throws {
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data(Array($0)) }
        let encodedData = try JSONEncoder.defaultEncoder.encode(data)
        try await subject.setValue(data, for: .authenticatorKey)

        let attributes = try XCTUnwrap(keychainService.addAttributes as? [CFString: Any])
        try XCTAssertEqual(XCTUnwrap(attributes[kSecAttrAccessGroup] as? String), accessGroup)
        try XCTAssertEqual(XCTUnwrap(attributes[kSecAttrAccessible] as? String),
                           String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly))
        try XCTAssertEqual(XCTUnwrap(attributes[kSecAttrAccount] as? String),
                           SharedKeychainItem.authenticatorKey.unformattedKey)
        try XCTAssertEqual(XCTUnwrap(attributes[kSecClass] as? String),
                           String(kSecClassGenericPassword))
        try XCTAssertEqual(XCTUnwrap(attributes[kSecValueData] as? Data), encodedData)
    }
}
