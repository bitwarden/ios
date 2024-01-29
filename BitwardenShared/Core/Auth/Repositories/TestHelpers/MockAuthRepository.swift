@testable import BitwardenShared

class MockAuthRepository: AuthRepository {
    var accountsResult: Result<[ProfileSwitcherItem], Error> = .failure(StateServiceError.noAccounts)
    var activeAccountResult: Result<ProfileSwitcherItem, Error> = .failure(StateServiceError.noActiveAccount)
    var allowBiometricUnlock: Bool?
    var allowBiometricUnlockResult: Result<Void, Error> = .success(())
    var accountForItemResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var clearPinsCalled = false
    var deleteAccountCalled = false
    var deviceId: String = ""
    var email: String = ""
    var encryptedPin: String = "123"
    var fingerprintPhraseResult: Result<String, Error> = .success("fingerprint")
    var isLockedResult: Result<Bool, Error> = .success(true)
    var isPinUnlockAvailable = false
    var lockVaultUserId: String?
    var logoutCalled = false
    var logoutUserId: String?
    var logoutResult: Result<Void, Error> = .success(())
    var passwordStrengthEmail: String?
    var passwordStrengthPassword: String?
    var passwordStrengthResult: UInt8 = 0
    var pinProtectedUserKey = "123"
    var setActiveAccountId: String?
    var setActiveAccountResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var setVaultTimeoutError: Error?
    var unlockVaultPassword: String?
    var unlockVaultPIN: String?
    var unlockWithPasswordResult: Result<Void, Error> = .success(())
    var unlockWithPINResult: Result<Void, Error> = .success(())

    var unlockVaultResult: Result<Void, Error> = .success(())
    var unlockVaultWithBiometricsResult: Result<Void, Error> = .success(())
    var unlockVaultWithNeverlockResult: Result<Void, Error> = .success(())

    func allowBioMetricUnlock(_ enabled: Bool) async throws {
        allowBiometricUnlock = enabled
        try allowBiometricUnlockResult.get()
    }

    func clearPins() async throws {
        clearPinsCalled = true
    }

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

    func getFingerprintPhrase() async throws -> String {
        try fingerprintPhraseResult.get()
    }

    func isLocked(userId: String?) async throws -> Bool {
        try isLockedResult.get()
    }

    func isPinUnlockAvailable() async throws -> Bool {
        isPinUnlockAvailable
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

    func setActiveAccount(userId: String) async throws -> Account {
        setActiveAccountId = userId
        return try setActiveAccountResult.get()
    }

    func setPins(_ pin: String, requirePasswordAfterRestart _: Bool) async throws {
        encryptedPin = pin
        pinProtectedUserKey = pin
    }

    func setVaultTimeout(value: BitwardenShared.SessionTimeoutValue, userId: String?) async throws {
        if let setVaultTimeoutError {
            throw setVaultTimeoutError
        }
    }

    func unlockVaultWithPIN(pin: String) async throws {
        unlockVaultPIN = pin
        try unlockWithPINResult.get()
    }

    func unlockVaultWithPassword(password: String) async throws {
        unlockVaultPassword = password
        try unlockWithPasswordResult.get()
    }

    func unlockVaultWithBiometrics() async throws {
        try unlockVaultWithBiometricsResult.get()
    }

    func unlockVaultWithNeverlockKey() async throws {
        try unlockVaultWithNeverlockResult.get()
    }
}
