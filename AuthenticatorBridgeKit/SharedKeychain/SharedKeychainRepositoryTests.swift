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

    // MARK: Tests - AccountAutoLogoutTime

    /// `getAccountAutoLogoutTime()` retrieves the account auto-logout time via the facade.
    ///
    func test_getAccountAutoLogoutTime_success() async throws {
        let date = Date(timeIntervalSince1970: 12345)
        keychainServiceFacade.getValueReturnValue = try String(
            data: JSONEncoder.defaultEncoder.encode(date),
            encoding: .utf8,
        )

        let result = try await subject.getAccountAutoLogoutTime(userId: "1")

        XCTAssertEqual(result, date)
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem as? SharedKeychainItem,
            SharedKeychainItem.accountAutoLogout(userId: "1"),
        )
    }

    /// `getAccountAutoLogoutTime()` returns nil when the key is not found.
    ///
    func test_getAccountAutoLogoutTime_keyNotFound() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            SharedKeychainItem.accountAutoLogout(userId: "1"),
        )

        let result = try await subject.getAccountAutoLogoutTime(userId: "1")

        XCTAssertNil(result)
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem as? SharedKeychainItem,
            SharedKeychainItem.accountAutoLogout(userId: "1"),
        )
    }

    /// `getAccountAutoLogoutTime()` rethrows errors other than keyNotFound.
    ///
    func test_getAccountAutoLogoutTime_rethrowsError() async {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.osStatusError(-1)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            _ = try await subject.getAccountAutoLogoutTime(userId: "1")
        }
    }

    /// `setAccountAutoLogoutTime()` sets the account auto-logout time via the facade.
    ///
    func test_setAccountAutoLogoutTime_success() async throws {
        let date = Date(timeIntervalSince1970: 12345)

        try await subject.setAccountAutoLogoutTime(date, userId: "1")

        XCTAssertTrue(keychainServiceFacade.setValueCalled)
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item as? SharedKeychainItem,
            SharedKeychainItem.accountAutoLogout(userId: "1"),
        )
        let valueString = try XCTUnwrap(keychainServiceFacade.setValueReceivedArguments?.value)
        let decodedDate = try JSONDecoder.defaultDecoder.decode(
            Date.self,
            from: XCTUnwrap(valueString.data(using: .utf8)),
        )
        XCTAssertEqual(decodedDate, date)
    }

    /// `setAccountAutoLogoutTime()` deletes the account auto-logout time when nil is passed.
    ///
    func test_setAccountAutoLogoutTime_nil() async throws {
        try await subject.setAccountAutoLogoutTime(nil, userId: "1")

        XCTAssertEqual(
            keychainServiceFacade.deleteValueReceivedItem as? SharedKeychainItem,
            SharedKeychainItem.accountAutoLogout(userId: "1"),
        )
    }

    /// `setAccountAutoLogoutTime()` rethrows errors from the facade.
    ///
    func test_setAccountAutoLogoutTime_rethrowsError() async {
        keychainServiceFacade.setValueThrowableError = KeychainServiceError.osStatusError(-1)
        let date = Date(timeIntervalSince1970: 12345)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            try await subject.setAccountAutoLogoutTime(date, userId: "1")
        }
    }

    // MARK: Tests - AuthenticatorKey

    /// `deleteAuthenticatorKey()` deletes the authenticator key via the facade.
    ///
    func test_deleteAuthenticatorKey_success() async throws {
        try await subject.deleteAuthenticatorKey()

        XCTAssertEqual(
            keychainServiceFacade.deleteValueReceivedItem as? SharedKeychainItem,
            SharedKeychainItem.authenticatorKey,
        )
    }

    /// `deleteAuthenticatorKey()` rethrows errors from the facade.
    ///
    func test_deleteAuthenticatorKey_rethrowsError() async {
        keychainServiceFacade.deleteValueThrowableError = KeychainServiceError.osStatusError(-1)

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            try await subject.deleteAuthenticatorKey()
        }
    }

    /// `getAuthenticatorKey()` retrieves the authenticator key via the facade.
    ///
    func test_getAuthenticatorKey_success() async throws {
        let data = Data([1, 2, 3])
        keychainServiceFacade.getValueReturnValue = try String(
            data: JSONEncoder.defaultEncoder.encode(data),
            encoding: .utf8,
        )

        let result = try await subject.getAuthenticatorKey()

        XCTAssertEqual(result, data)
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem as? SharedKeychainItem,
            SharedKeychainItem.authenticatorKey,
        )
    }

    /// `getAuthenticatorKey()` throws `keyNotFound` when the key is not in storage.
    ///
    func test_getAuthenticatorKey_keyNotFound() async {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            SharedKeychainItem.authenticatorKey,
        )

        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(SharedKeychainItem.authenticatorKey)) {
            _ = try await subject.getAuthenticatorKey()
        }
    }

    /// `setAuthenticatorKey()` sets the authenticator key via the facade.
    ///
    func test_setAuthenticatorKey_success() async throws {
        let data = Data([1, 2, 3])

        try await subject.setAuthenticatorKey(data)

        XCTAssertTrue(keychainServiceFacade.setValueCalled)
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item as? SharedKeychainItem,
            SharedKeychainItem.authenticatorKey,
        )
        let valueString = try XCTUnwrap(keychainServiceFacade.setValueReceivedArguments?.value)
        let decodedData = try JSONDecoder.defaultDecoder.decode(
            Data.self,
            from: XCTUnwrap(valueString.data(using: .utf8)),
        )
        XCTAssertEqual(decodedData, data)
    }

    /// `setAuthenticatorKey()` rethrows errors from the facade.
    ///
    func test_setAuthenticatorKey_rethrowsError() async {
        keychainServiceFacade.setValueThrowableError = KeychainServiceError.osStatusError(-1)
        let data = Data([1, 2, 3])

        await assertAsyncThrows(error: KeychainServiceError.osStatusError(-1)) {
            try await subject.setAuthenticatorKey(data)
        }
    }
}
