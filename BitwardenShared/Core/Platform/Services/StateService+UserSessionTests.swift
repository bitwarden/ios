// swiftlint:disable:this file_name

import BitwardenKit
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - StateService UserSession Tests

extension StateServiceTests {
    // MARK: Last Active Time

    /// `getLastActiveTime(userId:)` gets the user's last active time.
//    func test_getLastActiveTime() async throws {
//        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))
//
//        try await subject.setLastActiveTime(Date())
//        let lastActiveTime = try await subject.getLastActiveTime()
//        XCTAssertEqual(
//            lastActiveTime!.timeIntervalSince1970,
//            Date().timeIntervalSince1970,
//            accuracy: 1.0,
//        )
//    }

    // MARK: Vault Timeout

    /// `.getVaultTimeout(userId:)` gets the user's vault timeout.
    func test_getVaultTimeout() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        try await subject.setVaultTimeout(value: .custom(20), userId: "1")
        let key = userSessionKeychainRepository.setVaultTimeoutReceivedArguments
        XCTAssertEqual(key?.minutes, 20)
        XCTAssertEqual(key?.userId, "1")

        userSessionKeychainRepository.getVaultTimeoutReturnValue = 20
        let vaultTimeout = try await subject.getVaultTimeout(userId: "1")
        XCTAssertEqual(vaultTimeout, .custom(20))
    }

    /// `.getVaultTimeout(userId:)` gets the default vault timeout for the user if a value isn't set.
    func test_getVaultTimeout_default() async throws {
        let item = KeychainItem.vaultTimeout(userId: "1")
        keychainRepository.getVaultTimeoutResult = .failure(KeychainServiceError.keyNotFound(item))

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let vaultTimeout = try await subject.getVaultTimeout()
        XCTAssertEqual(vaultTimeout, .fifteenMinutes)
    }

    /// `.getVaultTimeout(userId:)` gets the user's vault timeout when it's set to never lock.
    func test_getVaultTimeout_neverLock() async throws {
        let item = KeychainItem.vaultTimeout(userId: "1")
        keychainRepository.getVaultTimeoutResult = .failure(KeychainServiceError.keyNotFound(item))
        keychainRepository.mockStorage[keychainRepository.formattedKey(for: .neverLock(userId: "1"))] = "NEVER_LOCK_KEY"

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let vaultTimeout = try await subject.getVaultTimeout()
        XCTAssertEqual(vaultTimeout, .never)
    }

    /// `getVaultTimeout(userId:)` returns the default timeout if the user has a never lock value
    /// stored but the never lock key doesn't exist.
    func test_getVaultTimeout_neverLock_missingKey() async throws {
        appSettingsStore.vaultTimeout["1"] = -2

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let vaultTimeout = try await subject.getVaultTimeout()
        XCTAssertEqual(vaultTimeout, .fifteenMinutes)
    }
}
