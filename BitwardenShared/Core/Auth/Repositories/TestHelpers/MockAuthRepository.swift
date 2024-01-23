@testable import BitwardenShared

class MockAuthRepository: AuthRepository {
    var accountsResult: Result<[ProfileSwitcherItem], Error> = .failure(StateServiceError.noAccounts)
    var activeAccountResult: Result<ProfileSwitcherItem, Error> = .failure(StateServiceError.noActiveAccount)
    var allowBiometricUnlock: Bool?
    var allowBiometricUnlockResult: Result<Void, Error> = .success(())
    var accountForItemResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var deleteAccountCalled = false
    var fingerprintPhraseResult: Result<String, Error> = .success("fingerprint")
    var lockVaultUserId: String?
    var logoutCalled = false
    var logoutUserId: String?
    var logoutResult: Result<Void, Error> = .success(())
    var passwordStrengthEmail: String?
    var passwordStrengthPassword: String?
    var passwordStrengthResult: UInt8 = 0
    var setActiveAccountResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var unlockVaultPassword: String?
    var unlockVaultResult: Result<Void, Error> = .success(())
    var unlockVaultWithBiometricsResult: Result<Void, Error> = .success(())

    func deleteAccount(passwordText _: String) async throws {
        deleteAccountCalled = true
    }

    func getAccounts() async throws -> [ProfileSwitcherItem] {
        try accountsResult.get()
    }

    func getActiveAccount() async throws -> ProfileSwitcherItem {
        try activeAccountResult.get()
    }

    func getAccount(for _: String) async throws -> Account {
        try accountForItemResult.get()
    }

    func getFingerprintPhrase(userId _: String?) async throws -> String {
        try fingerprintPhraseResult.get()
    }

    func passwordStrength(email: String, password: String) async -> UInt8 {
        passwordStrengthEmail = email
        passwordStrengthPassword = password
        return passwordStrengthResult
    }

    func lockVault(userId: String?) async {
        lockVaultUserId = userId
    }

    func logout(userId: String?) async throws {
        logoutUserId = userId
        try await logout()
    }

    func logout() async throws {
        logoutCalled = true
        try logoutResult.get()
    }

    func setActiveAccount(userId _: String) async throws -> Account {
        try setActiveAccountResult.get()
    }

    func allowBioMetricUnlock(_ enabled: Bool, userId: String?) async throws {
        allowBiometricUnlock = enabled
        try allowBiometricUnlockResult.get()
    }

    func unlockVault(password: String) async throws {
        unlockVaultPassword = password
        try unlockVaultResult.get()
    }

    func unlockVaultWithBiometrics() async throws {
        try unlockVaultWithBiometricsResult.get()
    }
}
