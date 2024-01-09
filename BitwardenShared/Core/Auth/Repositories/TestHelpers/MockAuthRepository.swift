@testable import BitwardenShared

class MockAuthRepository: AuthRepository {
    var accountsResult: Result<[ProfileSwitcherItem], Error> = .failure(StateServiceError.noAccounts)
    var activeAccountResult: Result<ProfileSwitcherItem, Error> = .failure(StateServiceError.noActiveAccount)
    var accountForItemResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var deleteAccountCalled = false
    var logoutCalled = false
    var pinKeyEncryptedUserKey = "123"
    var pinKeyEncryptedUserKeyResult: Result<String, Error> = .success("123")
    var setActiveAccountResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var unlockWithPINCalled = false
    var unlockVaultPassword: String?
    var unlockVaultPIN: String?
    var unlockVaultResult: Result<Void, Error> = .success(())
    var unlockWithPINResult: Result<Void, Error> = .success(())

    func deleteAccount(passwordText: String) async throws {
        deleteAccountCalled = true
    }

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

    func setActiveAccount(userId: String) async throws -> Account {
        try setActiveAccountResult.get()
    }

    func setPinKeyEncryptedUserKey(pin: String) async throws {
        pinKeyEncryptedUserKey = pin
    }

    func unlockWithPIN(_ pin: String) async throws {
        unlockVaultPIN = pin
        try unlockWithPINResult.get()
    }

    func unlockVault(password: String) async throws {
        unlockVaultPassword = password
        try unlockVaultResult.get()
    }
}
