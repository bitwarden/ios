@testable import BitwardenShared

class MockVaultCoordinatorDelegate: VaultCoordinatorDelegate {
    var addAccountTapped = false
    var accountTapped = [String]()
    var hasManuallyLocked = false
    var lockVaultId: String?
    var logoutTapped = false
    var logoutUserId: String?
    var presentLoginRequestRequest: LoginRequest?
    var switchAccountAuthCompletionRoute: AppRoute?
    var switchAccountIsAutomatic = false
    var switchAccountUserId: String?
    var switchedAccounts = false
    var switchToSettingsTabRoute: SettingsRoute?
    var userInitiated: Bool?

    func lockVault(userId: String?, isManuallyLocking: Bool) {
        lockVaultId = userId
        hasManuallyLocked = isManuallyLocking
    }

    func logout(userId: String?, userInitiated: Bool) {
        self.userInitiated = userInitiated
        logoutUserId = userId
        logoutTapped = true
    }

    func didTapAddAccount() {
        addAccountTapped = true
    }

    func didTapAccount(userId: String) {
        accountTapped.append(userId)
    }

    func presentLoginRequest(_ loginRequest: LoginRequest) {
        presentLoginRequestRequest = loginRequest
    }

    func switchAccount(userId: String, isAutomatic: Bool, authCompletionRoute: AppRoute?) {
        switchAccountAuthCompletionRoute = authCompletionRoute
        switchAccountIsAutomatic = isAutomatic
        switchAccountUserId = userId
        switchedAccounts = true
    }

    func switchToSettingsTab(route: SettingsRoute) {
        switchToSettingsTabRoute = route
    }
}
