@testable import BitwardenShared

class MockSettingsCoordinatorDelegate: SettingsCoordinatorDelegate {
    var didCompleteLoginsImportCalled = false
    var didDeleteAccountCalled = false
    var didLockVaultCalled = false
    var didLogoutCalled = false
    var hasManuallyLockedVault = false
    var lockedId: String?
    var loggedOutId: String?
    var switchAccountCalled = false
    var switchUserId: String?
    var wasLogoutUserInitiated: Bool?
    var wasSwitchAutomatic: Bool?

    func didCompleteLoginsImport() {
        didCompleteLoginsImportCalled = true
    }

    func didDeleteAccount() {
        didDeleteAccountCalled = true
    }

    func lockVault(userId: String?, isManuallyLocking: Bool) {
        lockedId = userId
        didLockVaultCalled = true
        hasManuallyLockedVault = isManuallyLocking
    }

    func logout(userId: String?, userInitiated: Bool) {
        loggedOutId = userId
        wasLogoutUserInitiated = userInitiated
        didLogoutCalled = true
    }

    func switchAccount(isAutomatic: Bool, userId: String) {
        switchAccountCalled = true
        wasSwitchAutomatic = isAutomatic
        switchUserId = userId
    }
}
