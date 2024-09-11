import CryptoKit
import Foundation
import XCTest

@testable import AuthenticatorSyncShared

final class SharedKeychainRepositoryTests: AuthenticatorSyncSharedTestCase {
    // MARK: Properties

    let accessGroup = "group.com.example.bitwarden"
    var keychainService: MockAuthenticatorKeychainService!
    var subject: DefaultSharedKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        keychainService = MockAuthenticatorKeychainService()
        subject = DefaultSharedKeychainRepository(
            appSecAttrAccessGroupShared: accessGroup,
            keychainService: keychainService
        )
    }

    override func tearDown() {
        keychainService = nil
        subject = nil
    }

    // MARK: Tests

    /// Verify that `deleteAuthenticatorKey()` issues a delete with the correct search attributes specified.
    ///
    func testDeleteAuthenticatorKey() async throws {
        try subject.deleteAuthenticatorKey()

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

    /// Verify that `getAuthenticatorKey()` returns a value successfully when one is set. Additionally, verify the
    /// search attributes are specified correctly.
    ///
    func testGetAuthenticatorKey() async throws {
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data(Array($0)) }

        keychainService.setSearchResultData(data)

        let returnData = try await subject.getAuthenticatorKey()
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

    /// Verify that `getAuthenticatorKey()` fails with an error when the Authenticator is not present in the keychain
    ///
    func testGetAuthenticatorKeyFailed() async throws {
        let error = AuthenticatorKeychainServiceError.keyNotFound(SharedKeychainItem.authenticatorKey)
        keychainService.searchResult = .failure(error)

        await assertAsyncThrows(error: error) {
            _ = try await subject.getAuthenticatorKey()
        }
    }

    /// Verify that `setAuthenticatorKey(_:)` sets a value with the correct search attributes specified.
    ///
    func testSetAuthenticatorKey() async throws {
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data(Array($0)) }
        try await subject.setAuthenticatorKey(data)

        let attributes = try XCTUnwrap(keychainService.addAttributes as? [CFString: Any])
        try XCTAssertEqual(XCTUnwrap(attributes[kSecAttrAccessGroup] as? String), accessGroup)
        try XCTAssertEqual(XCTUnwrap(attributes[kSecAttrAccessible] as? String),
                           String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly))
        try XCTAssertEqual(XCTUnwrap(attributes[kSecAttrAccount] as? String),
                           SharedKeychainItem.authenticatorKey.unformattedKey)
        try XCTAssertEqual(XCTUnwrap(attributes[kSecClass] as? String),
                           String(kSecClassGenericPassword))
        try XCTAssertEqual(XCTUnwrap(attributes[kSecValueData] as? Data), data)
    }
}
