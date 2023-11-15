@testable import BitwardenShared

class MockAuthRepository: AuthRepository {
    var accountsResult: Result<[ProfileSwitcherItem], Error> = .failure(StateServiceError.noAccounts)
    var activeAccountResult: Result<ProfileSwitcherItem, Error> = .failure(StateServiceError.noActiveAccount)
    var logoutCalled = false
    var unlockVaultPassword: String?
    var unlockVaultResult: Result<Void, Error> = .success(())

    func getAccounts() async throws -> [ProfileSwitcherItem] {
        // TODO: BIT-1132 - Profile Switcher UI on Auth
        try accountsResult.get()
    }

    func getActiveAccount() async throws -> ProfileSwitcherItem {
        // TODO: BIT-1132 - Profile Switcher UI on Auth
        try activeAccountResult.get()
    }

    func logout() async throws {
        logoutCalled = true
    }

    func unlockVault(password: String) async throws {
        unlockVaultPassword = password
        try unlockVaultResult.get()
    }
}
