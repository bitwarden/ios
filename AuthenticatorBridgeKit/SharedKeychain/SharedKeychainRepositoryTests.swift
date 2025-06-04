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
            storage: storage
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

    /// `getLastActiveTime()` retrieves the last active time from storage.
    func test_getLastActiveTime_success() async throws {
        let date = Date(timeIntervalSince1970: 12345)
        storage.storage[.lastActiveTime(application: .passwordManager, userId: "1")] = date
        let lastActiveTime = try await subject.getLastActiveTime(application: .passwordManager, userId: "1")
        XCTAssertEqual(lastActiveTime, date)
    }

    /// `getLastActiveTime()` returns nil if the keychain doesn't contain a last active time for the application
    func test_getLastActiveTime_nil() async throws {
        let date = Date(timeIntervalSince1970: 12345)
        storage.storage[.lastActiveTime(application: .passwordManager, userId: "1")] = date
        await assertAsyncDoesNotThrow {
            let lastActiveTime = try await subject.getLastActiveTime(application: .authenticator, userId: "1")
            XCTAssertNil(lastActiveTime)
        }
    }

    /// `setLastActiveTime()` sets the last active time in storage.
    func test_setLastActiveTime_success() async throws {
        let date = Date(timeIntervalSince1970: 12345)
        try await subject.setLastActiveTime(date, application: .passwordManager, userId: "1")
        XCTAssertEqual(storage.storage[.lastActiveTime(application: .passwordManager, userId: "1")] as? Date, date)
    }

    /// `getVaultTimeout()` retrieves the vault timeout from storage.
    func test_getVaultTimeout_success() async throws {
        storage.storage[.vaultTimeout(application: .authenticator, userId: "1")] = SessionTimeoutValue.oneHour
        let vaultTimeout: SessionTimeoutValue?
        vaultTimeout = try await subject.getVaultTimeout(application: .authenticator, userId: "1") ?? .fifteenMinutes
        XCTAssertEqual(vaultTimeout, .oneHour)
    }

    /// `getVaultTimeout()` returns nil if the keychain doesn't contain a last active time for the application
    func test_getVaultTimeout_nil() async throws {
        storage.storage[.vaultTimeout(application: .authenticator, userId: "1")] = SessionTimeoutValue.oneHour
        await assertAsyncDoesNotThrow {
            let vaultTimeout: SessionTimeoutValue?
            vaultTimeout = try await subject.getVaultTimeout(application: .passwordManager, userId: "1")
            XCTAssertNil(vaultTimeout)
        }
    }

    /// `setVaultTimeout()` sets the vault timeout in storage.
    func test_setVaultTimeout_success() async throws {
        try await subject.setVaultTimeout(SessionTimeoutValue.oneHour, application: .authenticator, userId: "1")
        XCTAssertEqual(
            storage.storage[.vaultTimeout(application: .authenticator, userId: "1")] as? SessionTimeoutValue,
            .oneHour
        )
    }
}
