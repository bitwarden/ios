@testable import BitwardenShared

class MockAuthRepository: AuthRepository {
    var accountsResult: Result<[ProfileSwitcherItem], Error> = .failure(StateServiceError.noAccounts)
    var activeAccountResult: Result<ProfileSwitcherItem, Error> = .failure(StateServiceError.noActiveAccount)
    var accountForItemResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var logoutCalled = false
    var unlockVaultPassword: String?
    var unlockVaultResult: Result<Void, Error> = .success(())

    func getAccounts() async throws -> [ProfileSwitcherItem] {
        try accountsResult.get()
    }

    func getActiveAccount() async throws -> ProfileSwitcherItem {
        try activeAccountResult.get()
    }

    func getAccount(for userId: String) async throws -> BitwardenShared.Account {
        try accountForItemResult.get()
    }

    func logout() async throws {
        logoutCalled = true
    }

    func unlockVault(password: String) async throws {
        unlockVaultPassword = password
        try unlockVaultResult.get()
    }
}
