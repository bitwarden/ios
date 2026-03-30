import AuthenticatorBridgeKit
import BitwardenKit
import BitwardenKitMocks
import Foundation
import XCTest

final class SharedKeychainRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var keychainServiceFacade: MockKeychainServiceFacade!
    var subject: DefaultSharedKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        keychainServiceFacade = MockKeychainServiceFacade()
        subject = DefaultSharedKeychainRepository(
            keychainServiceFacade: keychainServiceFacade,
        )
    }

    override func tearDown() {
        super.tearDown()

        keychainServiceFacade = nil
        subject = nil
    }

    // MARK: Tests

    /// `deleteAuthenticatorKey()` deletes the authenticator key via the facade.
    ///
    func test_deleteAuthenticatorKey_success() async throws {
        try await subject.deleteAuthenticatorKey()

        XCTAssertEqual(
            keychainServiceFacade.deleteValueReceivedItem?.unformattedKey,
            SharedKeychainItem.authenticatorKey.unformattedKey
        )
    }

    /// `getAccountAutoLogoutTime()` retrieves the account auto-logout time via the facade.
    ///
    func test_getAccountAutoLogoutTime_success() async throws {
        let date = Date(timeIntervalSince1970: 12345)
        keychainServiceFacade.getValueReturnValue = String(
            data: try JSONEncoder.defaultEncoder.encode(date),
            encoding: .utf8
        )

        let result = try await subject.getAccountAutoLogoutTime(userId: "1")

        XCTAssertEqual(result, date)
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            SharedKeychainItem.accountAutoLogout(userId: "1").unformattedKey
        )
    }

    /// `getAuthenticatorKey()` throws `keyNotFound` when the key is not in storage.
    ///
    func test_getAuthenticatorKey_keyNotFound() async {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            SharedKeychainItem.authenticatorKey
        )

        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(SharedKeychainItem.authenticatorKey)) {
            _ = try await subject.getAuthenticatorKey()
        }
    }

    /// `getAuthenticatorKey()` retrieves the authenticator key via the facade.
    ///
    func test_getAuthenticatorKey_success() async throws {
        let data = Data([1, 2, 3])
        keychainServiceFacade.getValueReturnValue = String(
            data: try JSONEncoder.defaultEncoder.encode(data),
            encoding: .utf8
        )

        let result = try await subject.getAuthenticatorKey()

        XCTAssertEqual(result, data)
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            SharedKeychainItem.authenticatorKey.unformattedKey
        )
    }

    /// `setAccountAutoLogoutTime()` sets the account auto-logout time via the facade.
    ///
    func test_setAccountAutoLogoutTime_success() async throws {
        let date = Date(timeIntervalSince1970: 12345)

        try await subject.setAccountAutoLogoutTime(date, userId: "1")

        XCTAssertTrue(keychainServiceFacade.setValueCalled)
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            SharedKeychainItem.accountAutoLogout(userId: "1").unformattedKey
        )
    }

    /// `setAuthenticatorKey()` sets the authenticator key via the facade.
    ///
    func test_setAuthenticatorKey_success() async throws {
        let data = Data([1, 2, 3])

        try await subject.setAuthenticatorKey(data)

        XCTAssertTrue(keychainServiceFacade.setValueCalled)
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            SharedKeychainItem.authenticatorKey.unformattedKey
        )
    }
}
