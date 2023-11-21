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

    /// `unlockVault(userId:)` can unlock a user's vault.
    func test_lockVault_false_unknownUser() async {
        vaultTimeoutService.timeoutStore = [:]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, [:])

        await subject.unlockVault(userId: "123")
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": false])
    }

    /// `unlockVault(userId:)` can unlock a user's vault.
    func test_lockVault_false_knownUser() async {
        vaultTimeoutService.timeoutStore = ["123": true]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": true])

        await subject.unlockVault(userId: "123")
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": false])
    }

    /// `lockVault` can lock a user's vault.
    func test_lockVault_true_unknownUser() async {
        vaultTimeoutService.timeoutStore = [:]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, [:])

        await subject.lockVault(userId: "123")
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": true])
    }

    /// `lockVault` can lock a user's vault.
    func test_lockVault_true_knownUser() async {
        vaultTimeoutService.timeoutStore = ["123": false]
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": false])

        await subject.lockVault(userId: "123")
        XCTAssertEqual(vaultTimeoutService.isLockedSubject.value, ["123": true])
    }

    /// `logout()` has the state service log the user out.
    func test_logout() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        try await subject.logout()

        XCTAssertEqual(stateService.accountsLoggedOut, ["1"])
    }
}
