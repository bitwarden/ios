// swiftlint:disable:this file_name

import BitwardenKit
import XCTest

@testable import BitwardenShared

// MARK: - KeychainRepositoryUserSessionTests

final class KeychainRepositoryUserSessionTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var keychainService: MockKeychainService!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        keychainService = MockKeychainService()
        subject = DefaultKeychainRepository(
            appIdService: AppIdService(
                appSettingStore: appSettingsStore,
            ),
            keychainService: keychainService,
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        keychainService = nil
        subject = nil
    }

    // MARK: Tests - Last Active Monotonic Time

    /// `getLastActiveMonotonicTime(userId:)` returns the stored last active monotonic time.
    func test_getLastActiveMonotonicTime() async throws {
        let expectedMonotonicTime: TimeInterval = 12345.67
        keychainService.setSearchResultData(string: String(expectedMonotonicTime))

        let monotonicTime = try await subject.getLastActiveMonotonicTime(userId: "1")
        XCTAssertEqual(monotonicTime, expectedMonotonicTime)
    }

    /// `getLastActiveMonotonicTime(userId:)` returns nil when no value is stored.
    func test_getLastActiveMonotonicTime_notFound() async throws {
        let error = KeychainServiceError.osStatusError(errSecItemNotFound)
        keychainService.searchResult = .failure(error)

        let monotonicTime = try await subject.getLastActiveMonotonicTime(userId: "1")
        XCTAssertNil(monotonicTime)
    }

    /// `getLastActiveMonotonicTime(userId:)` throws an error for errors other than item not found.
    func test_getLastActiveMonotonicTime_error() async {
        let error = KeychainServiceError.osStatusError(-1)
        keychainService.searchResult = .failure(error)

        await assertAsyncThrows(error: error) {
            _ = try await subject.getLastActiveMonotonicTime(userId: "1")
        }
    }

    /// `setLastActiveMonotonicTime(_:userId:)` stores the last active monotonic time.
    func test_setLastActiveMonotonicTime() async throws {
        let monotonicTime: TimeInterval = 98765.43

        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [],
                nil,
            )!,
        )

        try await subject.setLastActiveMonotonicTime(monotonicTime, userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        let valueData = try XCTUnwrap(attributes[kSecValueData] as? Data)
        let storedValue = try XCTUnwrap(String(data: valueData, encoding: .utf8))
        XCTAssertEqual(TimeInterval(storedValue), monotonicTime)
    }

    /// `setLastActiveMonotonicTime(_:userId:)` clears the monotonic time when nil is passed.
    func test_setLastActiveMonotonicTime_nil() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [],
                nil,
            )!,
        )

        try await subject.setLastActiveMonotonicTime(nil, userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        let valueData = try XCTUnwrap(attributes[kSecValueData] as? Data)
        let storedValue = try XCTUnwrap(String(data: valueData, encoding: .utf8))
        XCTAssertEqual(storedValue, "")
    }

    /// `setLastActiveMonotonicTime(_:userId:)` throws an error if one occurs.
    func test_setLastActiveMonotonicTime_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainService.addResult = .failure(error)

        await assertAsyncThrows(error: error) {
            try await subject.setLastActiveMonotonicTime(12345.0, userId: "1")
        }
    }

    // MARK: Tests - Last Active Time

    /// `getLastActiveTime(userId:)` returns the stored last active time.
    ///
    func test_getLastActiveTime() async throws {
        keychainService.setSearchResultData(string: "1234567890")
        let lastActiveTime = try await subject.getLastActiveTime(userId: "1")
        XCTAssertEqual(lastActiveTime, Date(timeIntervalSince1970: 1_234_567_890))
    }

    /// `getLastActiveTime(userId:)` throws an error if one occurs.
    ///
    func test_getLastActiveTime_error() async {
        let error = KeychainServiceError.keyNotFound(KeychainItem.lastActiveTime(userId: "1"))
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getLastActiveTime(userId: "1")
        }
    }

    /// `setLastActiveTime(_:userId:)` stores the last active time with correct attributes.
    ///
    func test_setLastActiveTime() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [],
                nil,
            )!,
        )
        keychainService.setSearchResultData(string: "1234567890")
        try await subject.setLastActiveTime(Date(timeIntervalSince1970: 1_234_567_890), userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        try XCTAssertEqual(
            String(data: XCTUnwrap(attributes[kSecValueData] as? Data), encoding: .utf8),
            "1234567890.0",
        )
        let protection = try XCTUnwrap(keychainService.accessControlProtection as? String)
        XCTAssertEqual(protection, String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
    }

    /// `setLastActiveTime(_:userId:)` throws an error if one occurs.
    ///
    func test_setLastActiveTime_error() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainService.accessControlResult = .failure(error)
        await assertAsyncThrows(error: error) {
            try await subject.setLastActiveTime(Date(timeIntervalSince1970: 1_234_567_890), userId: "1")
        }
    }

    // MARK: Tests - Unsuccessful Unlock Attempts

    /// `getUnsuccessfulUnlockAttempts(userId:)` returns the stored value of unsuccessful unlock attempts.
    func test_getUnsuccessfulUnlockAttempts() async throws {
        keychainService.setSearchResultData(string: "4")
        let attempts = try await subject.getUnsuccessfulUnlockAttempts(userId: "1")
        XCTAssertEqual(attempts, 4)
    }

    /// `getUnsuccessfulUnlockAttempts(userId:)` throws an error if one occurs.
    ///
    func test_getUnsuccessfulUnlockAttempts_error() async {
        let error = KeychainServiceError.keyNotFound(KeychainItem.unsuccessfulUnlockAttempts(userId: "1"))
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getUnsuccessfulUnlockAttempts(userId: "1")
        }
    }

    /// `setUnsuccessfulUnlockAttempts(_:userId:)` stores the number of unsuccessful unlock attempts.
    ///
    func test_setUnsuccessfulUnlockAttempts() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [],
                nil,
            )!,
        )
        keychainService.setSearchResultData(string: "2")
        try await subject.setUnsuccessfulUnlockAttempts(3, userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        try XCTAssertEqual(
            String(data: XCTUnwrap(attributes[kSecValueData] as? Data), encoding: .utf8),
            "3",
        )
        let protection = try XCTUnwrap(keychainService.accessControlProtection as? String)
        XCTAssertEqual(protection, String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
    }

    // MARK: Tests - Vault Timeout

    /// `getVaultTimeout(userId:)` returns the stored vault timeout.
    ///
    func test_getVaultTimeout() async throws {
        keychainService.setSearchResultData(string: "15")
        let vaultTimeout = try await subject.getVaultTimeout(userId: "1")
        XCTAssertEqual(vaultTimeout, 15)
    }

    /// `getVaultTimeout(userId:)` throws an error if one occurs.
    ///
    func test_getVaultTimeout_error() async {
        let error = KeychainServiceError.keyNotFound(KeychainItem.vaultTimeout(userId: "1"))
        keychainService.searchResult = .failure(error)
        await assertAsyncThrows(error: error) {
            _ = try await subject.getVaultTimeout(userId: "1")
        }
    }

    /// `setVaultTimeout(_:userId:)` stores the vault timeout with correct attributes.
    ///
    func test_setVaultTimeout() async throws {
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [],
                nil,
            )!,
        )
        keychainService.setSearchResultData(string: "30")
        try await subject.setVaultTimeout(minutes: 30, userId: "1")

        let attributes = try XCTUnwrap(keychainService.addAttributes) as Dictionary
        try XCTAssertEqual(
            String(data: XCTUnwrap(attributes[kSecValueData] as? Data), encoding: .utf8),
            "30",
        )
        let protection = try XCTUnwrap(keychainService.accessControlProtection as? String)
        XCTAssertEqual(protection, String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
    }

    /// `setVaultTimeout(_:userId:)` throws an error if one occurs.
    ///
    func test_setVaultTimeout_accessControlError() async {
        let error = KeychainServiceError.accessControlFailed(nil)
        keychainService.accessControlResult = .failure(error)
        await assertAsyncThrows(error: error) {
            try await subject.setVaultTimeout(minutes: 30, userId: "1")
        }
    }
}
