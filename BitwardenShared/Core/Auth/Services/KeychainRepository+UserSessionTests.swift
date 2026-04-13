// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - KeychainRepositoryUserSessionTests

final class KeychainRepositoryUserSessionTests: BitwardenTestCase {
    // MARK: Properties

    var keychainServiceFacade: MockKeychainServiceFacade!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        keychainServiceFacade = MockKeychainServiceFacade()
        subject = DefaultKeychainRepository(
            keychainService: MockKeychainService(),
            keychainServiceFacade: keychainServiceFacade,
        )
    }

    override func tearDown() {
        super.tearDown()

        keychainServiceFacade = nil
        subject = nil
    }

    // MARK: Tests - Last Active Time

    /// `getLastActiveTime(userId:)` returns the stored last active time.
    ///
    func test_getLastActiveTime() async throws {
        keychainServiceFacade.getValueReturnValue = "1234567890"

        let result = try await subject.getLastActiveTime(userId: "1")

        XCTAssertEqual(result, Date(timeIntervalSince1970: 1_234_567_890))
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.lastActiveTime(userId: "1").unformattedKey,
        )
    }

    /// `getLastActiveTime(userId:)` returns nil when the item is not found.
    ///
    func test_getLastActiveTime_keyNotFound() async throws {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.lastActiveTime(userId: "1"))
        keychainServiceFacade.getValueThrowableError = error

        let result = try await subject.getLastActiveTime(userId: "1")

        XCTAssertNil(result)
    }

    /// `getLastActiveTime(userId:)` returns nil when the item is not found.
    ///
    func test_getLastActiveTime_itemNotFound() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        let result = try await subject.getLastActiveTime(userId: "1")

        XCTAssertNil(result)
    }

    /// `getLastActiveTime(userId:)` rethrows non-notFound errors.
    ///
    func test_getLastActiveTime_error() async {
        let error = KeychainServiceError.osStatusError(errSecInvalidItemRef)
        keychainServiceFacade.getValueThrowableError = error

        await assertAsyncThrows(error: error) {
            _ = try await subject.getLastActiveTime(userId: "1")
        }
    }

    /// `setLastActiveTime(_:userId:)` stores the timestamp string via the facade.
    ///
    func test_setLastActiveTime() async throws {
        try await subject.setLastActiveTime(Date(timeIntervalSince1970: 1_234_567_890), userId: "1")

        XCTAssertEqual(keychainServiceFacade.setValueReceivedArguments?.value, "1234567890.0")
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            BitwardenKeychainItem.lastActiveTime(userId: "1").unformattedKey,
        )
    }

    /// `setLastActiveTime(_:userId:)` rethrows errors from the facade.
    ///
    func test_setLastActiveTime_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainServiceFacade.setValueThrowableError = error

        await assertAsyncThrows(error: error) {
            try await subject.setLastActiveTime(Date(timeIntervalSince1970: 1_234_567_890), userId: "1")
        }
    }

    // MARK: Tests - Unsuccessful Unlock Attempts

    /// `getUnsuccessfulUnlockAttempts(userId:)` returns the stored unlock attempt count.
    ///
    func test_getUnsuccessfulUnlockAttempts() async throws {
        keychainServiceFacade.getValueReturnValue = "4"

        let result = try await subject.getUnsuccessfulUnlockAttempts(userId: "1")

        XCTAssertEqual(result, 4)
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.unsuccessfulUnlockAttempts(userId: "1").unformattedKey,
        )
    }

    /// `getUnsuccessfulUnlockAttempts(userId:)` rethrows errors from the facade.
    ///
    func test_getUnsuccessfulUnlockAttempts_error() async {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.unsuccessfulUnlockAttempts(userId: "1"))
        keychainServiceFacade.getValueThrowableError = error

        await assertAsyncThrows(error: error) {
            _ = try await subject.getUnsuccessfulUnlockAttempts(userId: "1")
        }
    }

    /// `setUnsuccessfulUnlockAttempts(_:userId:)` stores the count as a string via the facade.
    ///
    func test_setUnsuccessfulUnlockAttempts() async throws {
        try await subject.setUnsuccessfulUnlockAttempts(3, userId: "1")

        XCTAssertEqual(keychainServiceFacade.setValueReceivedArguments?.value, "3")
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            BitwardenKeychainItem.unsuccessfulUnlockAttempts(userId: "1").unformattedKey,
        )
    }

    // MARK: Tests - Vault Timeout

    /// `getVaultTimeout(userId:)` returns the stored vault timeout.
    ///
    func test_getVaultTimeout() async throws {
        keychainServiceFacade.getValueReturnValue = "15"

        let result = try await subject.getVaultTimeout(userId: "1")

        XCTAssertEqual(result, 15)
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.vaultTimeout(userId: "1").unformattedKey,
        )
    }

    /// `getVaultTimeout(userId:)` rethrows errors from the facade.
    ///
    func test_getVaultTimeout_error() async {
        let error = KeychainServiceError.keyNotFound(BitwardenKeychainItem.vaultTimeout(userId: "1"))
        keychainServiceFacade.getValueThrowableError = error

        await assertAsyncThrows(error: error) {
            _ = try await subject.getVaultTimeout(userId: "1")
        }
    }

    /// `setVaultTimeout(minutes:userId:)` stores the timeout as a string via the facade.
    ///
    func test_setVaultTimeout() async throws {
        try await subject.setVaultTimeout(minutes: 30, userId: "1")

        XCTAssertEqual(keychainServiceFacade.setValueReceivedArguments?.value, "30")
        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            BitwardenKeychainItem.vaultTimeout(userId: "1").unformattedKey,
        )
    }

    /// `setVaultTimeout(minutes:userId:)` rethrows errors from the facade.
    ///
    func test_setVaultTimeout_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainServiceFacade.setValueThrowableError = error

        await assertAsyncThrows(error: error) {
            try await subject.setVaultTimeout(minutes: 30, userId: "1")
        }
    }
}
