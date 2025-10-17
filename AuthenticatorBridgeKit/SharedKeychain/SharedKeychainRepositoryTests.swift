import AuthenticatorBridgeKit
import AuthenticatorBridgeKitMocks
import BitwardenKit
import BitwardenKitMocks
import CryptoKit
import Foundation
import XCTest

final class SharedKeychainRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var storage: MockSharedKeychainStorage!
    var subject: DefaultSharedKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        storage = MockSharedKeychainStorage()
        subject = DefaultSharedKeychainRepository(
            storage: storage,
        )
    }

    override func tearDown() {
        storage = nil
        subject = nil
    }

    // MARK: Tests

    /// `deleteAuthenticatorKey()` deletes the authenticator key from storage.
    func test_deleteAuthenticatorKey_success() async throws {
        storage.storage[.authenticatorKey] = Data()
        try await subject.deleteAuthenticatorKey()
        XCTAssertNil(storage.storage[.authenticatorKey])
    }

    /// `getAuthenticatorKey()` retrieves the authenticator key from storage.
    func test_getAuthenticatorKey_success() async throws {
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data(Array($0)) }
        storage.storage[.authenticatorKey] = data
        let authenticatorKey = try await subject.getAuthenticatorKey()
        XCTAssertEqual(authenticatorKey, data)
    }

    /// `getAuthenticatorKey()` throws an error if the key is not in storage.
    func test_getAuthenticatorKey_nil() async throws {
        await assertAsyncThrows(error: SharedKeychainServiceError.keyNotFound(.authenticatorKey)) {
            _ = try await subject.getAuthenticatorKey()
        }
    }

    /// `setAuthenticatorKey()` sets the authenticator key in storage.
    func test_setAuthenticatorKey_success() async throws {
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data(Array($0)) }
        try await subject.setAuthenticatorKey(data)
        XCTAssertEqual(storage.storage[.authenticatorKey] as? Data, data)
    }

    /// `getAccountAutoLogoutTime()` retrieves the last active time from storage.
    func test_getBWPMAccountAutoLogoutTime_success() async throws {
        let date = Date(timeIntervalSince1970: 12345)
        storage.storage[.accountAutoLogout(userId: "1")] = date
        let lastActiveTime = try await subject.getAccountAutoLogoutTime(userId: "1")
        XCTAssertEqual(lastActiveTime, date)
    }

    /// `setAccountAutoLogoutTime()` sets the last active time in storage.
    func test_setBWPMAccountAutoLogoutTime_success() async throws {
        let date = Date(timeIntervalSince1970: 12345)
        try await subject.setAccountAutoLogoutTime(date, userId: "1")
        XCTAssertEqual(storage.storage[.accountAutoLogout(userId: "1")] as? Date, date)
    }
}
