import AuthenticatorBridgeKit
import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

struct SharedKeychainRepositoryTests {
    // MARK: Properties

    var keychainServiceFacade: MockKeychainServiceFacade
    var subject: DefaultSharedKeychainRepository

    // MARK: Setup & Teardown

    init() {
        keychainServiceFacade = MockKeychainServiceFacade()
        subject = DefaultSharedKeychainRepository(
            keychainServiceFacade: keychainServiceFacade,
        )
    }

    // MARK: Tests - AccountAutoLogoutTime

    /// `getAccountAutoLogoutTime()` retrieves the account auto-logout time via the facade.
    @Test
    func getAccountAutoLogoutTime_success() async throws {
        let date = Date(timeIntervalSince1970: 12345)
        keychainServiceFacade.getValueReturnValue = try String(
            data: JSONEncoder.defaultEncoder.encode(date),
            encoding: .utf8,
        )

        let result = try await subject.getAccountAutoLogoutTime(userId: "1")

        #expect(result == date)
        let actualItem = keychainServiceFacade.getValueReceivedItem as? SharedKeychainItem
        let expectedItem = SharedKeychainItem.accountAutoLogout(userId: "1")
        #expect(actualItem == expectedItem)
    }

    /// `getAccountAutoLogoutTime()` returns nil when the key is not found.
    @Test
    func getAccountAutoLogoutTime_keyNotFound() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            SharedKeychainItem.accountAutoLogout(userId: "1"),
        )

        let result = try await subject.getAccountAutoLogoutTime(userId: "1")

        #expect(result == nil)
        let actualItem = keychainServiceFacade.getValueReceivedItem as? SharedKeychainItem
        let expectedItem = SharedKeychainItem.accountAutoLogout(userId: "1")
        #expect(actualItem == expectedItem)
    }

    /// `getAccountAutoLogoutTime()` rethrows errors other than keyNotFound.
    @Test
    func getAccountAutoLogoutTime_rethrowsError() async {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.osStatusError(-1)

        await #expect(throws: KeychainServiceError.osStatusError(-1)) {
            _ = try await subject.getAccountAutoLogoutTime(userId: "1")
        }
    }

    /// `setAccountAutoLogoutTime()` sets the account auto-logout time via the facade.
    @Test
    func setAccountAutoLogoutTime_success() async throws {
        let date = Date(timeIntervalSince1970: 12345)

        try await subject.setAccountAutoLogoutTime(date, userId: "1")

        #expect(keychainServiceFacade.setValueCalled)
        let actualItem = keychainServiceFacade.setValueReceivedArguments?.item as? SharedKeychainItem
        let expectedItem = SharedKeychainItem.accountAutoLogout(userId: "1")
        #expect(actualItem == expectedItem)
        let valueString = try #require(keychainServiceFacade.setValueReceivedArguments?.value)
        let valueData = try #require(valueString.data(using: .utf8))
        let decodedDate = try JSONDecoder.defaultDecoder.decode(Date.self, from: valueData)
        #expect(decodedDate == date)
    }

    /// `setAccountAutoLogoutTime()` deletes the account auto-logout time when nil is passed.
    @Test
    func setAccountAutoLogoutTime_nil() async throws {
        try await subject.setAccountAutoLogoutTime(nil, userId: "1")

        let actualItem = keychainServiceFacade.deleteValueReceivedItem as? SharedKeychainItem
        let expectedItem = SharedKeychainItem.accountAutoLogout(userId: "1")
        #expect(actualItem == expectedItem)
    }

    /// `setAccountAutoLogoutTime()` rethrows errors from the facade.
    @Test
    func setAccountAutoLogoutTime_rethrowsError() async {
        keychainServiceFacade.setValueThrowableError = KeychainServiceError.osStatusError(-1)
        let date = Date(timeIntervalSince1970: 12345)

        await #expect(throws: KeychainServiceError.osStatusError(-1)) {
            try await subject.setAccountAutoLogoutTime(date, userId: "1")
        }
    }

    // MARK: Tests - AuthenticatorKey

    /// `deleteAuthenticatorKey()` deletes the authenticator key via the facade.
    @Test
    func deleteAuthenticatorKey_success() async throws {
        try await subject.deleteAuthenticatorKey()

        let actualItem = keychainServiceFacade.deleteValueReceivedItem as? SharedKeychainItem
        let expectedItem = SharedKeychainItem.authenticatorKey
        #expect(actualItem == expectedItem)
    }

    /// `deleteAuthenticatorKey()` rethrows errors from the facade.
    @Test
    func deleteAuthenticatorKey_rethrowsError() async {
        keychainServiceFacade.deleteValueThrowableError = KeychainServiceError.osStatusError(-1)

        await #expect(throws: KeychainServiceError.osStatusError(-1)) {
            try await subject.deleteAuthenticatorKey()
        }
    }

    /// `getAuthenticatorKey()` retrieves the authenticator key via the facade.
    @Test
    func getAuthenticatorKey_success() async throws {
        let data = Data([1, 2, 3])
        keychainServiceFacade.getValueReturnValue = try String(
            data: JSONEncoder.defaultEncoder.encode(data),
            encoding: .utf8,
        )

        let result = try await subject.getAuthenticatorKey()

        #expect(result == data)
        let actualItem = keychainServiceFacade.getValueReceivedItem as? SharedKeychainItem
        let expectedItem = SharedKeychainItem.authenticatorKey
        #expect(actualItem == expectedItem)
    }

    /// `getAuthenticatorKey()` throws `keyNotFound` when the key is not in storage.
    @Test
    func getAuthenticatorKey_keyNotFound() async {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            SharedKeychainItem.authenticatorKey,
        )

        await #expect(throws: KeychainServiceError.keyNotFound(SharedKeychainItem.authenticatorKey)) {
            _ = try await subject.getAuthenticatorKey()
        }
    }

    /// `setAuthenticatorKey()` sets the authenticator key via the facade.
    @Test
    func setAuthenticatorKey_success() async throws {
        let data = Data([1, 2, 3])

        try await subject.setAuthenticatorKey(data)

        #expect(keychainServiceFacade.setValueCalled)
        let actualItem = keychainServiceFacade.setValueReceivedArguments?.item as? SharedKeychainItem
        let expectedItem = SharedKeychainItem.authenticatorKey
        #expect(actualItem == expectedItem)
        let valueString = try #require(keychainServiceFacade.setValueReceivedArguments?.value)
        let valueData = try #require(valueString.data(using: .utf8))
        let decodedData = try JSONDecoder.defaultDecoder.decode(Data.self, from: valueData)
        #expect(decodedData == data)
    }

    /// `setAuthenticatorKey()` rethrows errors from the facade.
    @Test
    func setAuthenticatorKey_rethrowsError() async {
        keychainServiceFacade.setValueThrowableError = KeychainServiceError.osStatusError(-1)
        let data = Data([1, 2, 3])

        await #expect(throws: KeychainServiceError.osStatusError(-1)) {
            try await subject.setAuthenticatorKey(data)
        }
    }
}
