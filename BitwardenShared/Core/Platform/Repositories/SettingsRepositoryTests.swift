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

    /// `lockVault` locks the user's vault.
    func test_lockVault() {
        XCTAssertFalse(vaultTimeoutService.isLockedSubject.value)

        subject.lockVault()
        XCTAssertTrue(vaultTimeoutService.isLockedSubject.value)
    }

    /// `logout()` has the state service log the user out.
    func test_logout() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        try await subject.logout()

        XCTAssertEqual(stateService.accountsLoggedOut, ["1"])
    }
}
