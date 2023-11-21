import XCTest

@testable import BitwardenShared

class SettingsRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var stateService: MockStateService!
    var subject: DefaultSettingsRepository!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultSettingsRepository(stateService: stateService, vaultTimeoutService: vaultTimeoutService)
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `isLocked` throws if no account exists
    func test_isLocked_unknownUser() {
        vaultTimeoutService.timeoutStore = [:]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, [:])

        XCTAssertThrowsError(try subject.isLocked(userId: "1")) { error in
            XCTAssertEqual(
                error as? VaultTimeoutServiceError,
                .noAccountFound
            )
        }
    }

    /// `isLocked` returns true for locked accounts
    func test_isLocked_lockedUser() {
        vaultTimeoutService.timeoutStore = ["123": true]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": true])

        XCTAssertTrue(try vaultTimeoutService.isLocked(userId: "123"))
    }

    /// `isLocked` returns false for unlocked accounts
    func test_isLocked_unlockedUser() {
        vaultTimeoutService.timeoutStore = ["123": false]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": false])

        XCTAssertFalse(try vaultTimeoutService.isLocked(userId: "123"))
    }

    /// `unlockVault(userId:)` can unlock a user's vault.
    func test_lockVault_false_unknownUser() {
        vaultTimeoutService.timeoutStore = [:]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, [:])

        subject.unlockVault(userId: "123")
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": false])
    }

    /// `unlockVault(userId:)` can unlock a user's vault.
    func test_lockVault_false_knownUser() {
        vaultTimeoutService.timeoutStore = ["123": true]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": true])

        subject.unlockVault(userId: "123")
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": false])
    }

    /// `lockVault` can lock a user's vault.
    func test_lockVault_true_unknownUser() {
        vaultTimeoutService.timeoutStore = [:]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, [:])

        subject.lockVault(userId: "123")
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": true])
    }

    /// `lockVault` can lock a user's vault.
    func test_lockVault_true_knownUser() {
        vaultTimeoutService.timeoutStore = ["123": false]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": false])

        subject.lockVault(userId: "123")
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": true])
    }

    /// `logout()` has the state service log the user out.
    func test_logout() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        try await subject.logout()

        XCTAssertEqual(stateService.accountsLoggedOut, ["1"])
    }
}
