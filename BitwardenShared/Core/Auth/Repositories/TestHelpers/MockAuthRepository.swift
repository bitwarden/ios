@testable import BitwardenShared

class MockAuthRepository: AuthRepository {
    var accountsResult: Result<[ProfileSwitcherItem], Error> = .failure(StateServiceError.noAccounts)
    var activeAccountResult: Result<ProfileSwitcherItem, Error> = .failure(StateServiceError.noActiveAccount)
    var accountForItemResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var clearPinsCalled = false
    var deleteAccountCalled = false
    var encryptedPin: String = "123"
    var fingerprintPhraseResult: Result<String, Error> = .success("fingerprint")
    var isPinUnlockAvailable = false
    var logoutCalled = false
    var logoutResult: Result<Void, Error> = .success(())
    var passwordStrengthEmail: String?
    var passwordStrengthPassword: String?
    var passwordStrengthResult: UInt8 = 0
    var pinProtectedUserKey = "123"
    var setActiveAccountResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var unlockVaultPassword: String?
    var unlockVaultPIN: String?
    var unlockWithPasswordResult: Result<Void, Error> = .success(())
    var unlockWithPINResult: Result<Void, Error> = .success(())

    func clearPins() async throws {
        clearPinsCalled = true
    }

    func deleteAccount(passwordText: String) async throws {
        deleteAccountCalled = true
    }

    func getAccounts() async throws -> [ProfileSwitcherItem] {
        try accountsResult.get()
    }

    func getActiveAccount() async throws -> ProfileSwitcherItem {
        try activeAccountResult.get()
    }

    func getAccount(for userId: String) async throws -> Account {
        try accountForItemResult.get()
    }

    func getFingerprintPhrase(userId: String?) async throws -> String {
        try fingerprintPhraseResult.get()
    }

    func isPinUnlockAvailable() async throws -> Bool {
        isPinUnlockAvailable
    }

    func passwordStrength(email: String, password: String) async -> UInt8 {
        passwordStrengthEmail = email
        passwordStrengthPassword = password
        return passwordStrengthResult
    }

    func logout() async throws {
        logoutCalled = true
        try logoutResult.get()
    }

    func setActiveAccount(userId: String) async throws -> Account {
        try setActiveAccountResult.get()
    }

    func setPins(_ pin: String, requirePasswordAfterRestart: Bool) async throws {
        encryptedPin = pin
        pinProtectedUserKey = pin
    }

    func unlockVaultWithPIN(pin: String) async throws {
        unlockVaultPIN = pin
        try unlockWithPINResult.get()
    }

    func unlockVaultWithPassword(password: String) async throws {
        unlockVaultPassword = password
        try unlockWithPasswordResult.get()
    }
}
