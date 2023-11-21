@testable import BitwardenShared

class MockSettingsRepository: SettingsRepository {
    var lockVaultCalled = false
    var logoutCalled = false

    func lockVault() {
        lockVaultCalled = true
    }

    func logout() async throws {
        logoutCalled = true
    }
}
