@testable import BitwardenShared

class MockAuthRepository: AuthRepository {
    var allowBiometricUnlock: Bool?
    var allowBiometricUnlockResult: Result<Void, Error> = .success(())
    var accountForItemResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var clearPinsCalled = false
    var createNewSsoUserRememberDevice: Bool = false
    var createNewSsoUserOrgIdentifier: String = ""
    var createNewSsoUserResult: Result<Void, Error> = .success(())
    var deleteAccountCalled = false
    var deviceId: String = ""
    var email: String = ""
    var encryptedPin: String = "123"
    var fingerprintPhraseResult: Result<String, Error> = .success("fingerprint")
    var activeAccount: Account?
    var altAccounts = [Account]()
    var getAccountError: Error?
    var hasMasterPassword: Bool = true
    var isLockedResult: Result<Bool, Error> = .success(true)
    var isPinUnlockAvailableResult: Result<Bool, Error> = .success(false)
    var lockVaultUserId: String?
    var logoutCalled = false
    var logoutUserId: String?
    var logoutResult: Result<Void, Error> = .success(())
    var passwordStrengthEmail: String?
    var passwordStrengthPassword: String?
    var passwordStrengthResult: UInt8 = 0
    var pinProtectedUserKey = "123"
    var profileSwitcherState: ProfileSwitcherState?
    var requestOtpCalled = false
    var requestOtpResult: Result<Void, Error> = .success(())
    var sessionTimeoutAction = [String: SessionTimeoutAction]()
    var setActiveAccountId: String?
    var setActiveAccountError: Error?
    var setMasterPasswordHint: String?
    var setMasterPasswordPassword: String?
    var setMasterPasswordOrganizationId: String?
    var setMasterPasswordOrganizationIdentifier: String?
    var setMasterPasswordResetPasswordAutoEnroll: Bool?
    var setMasterPasswordResult: Result<Void, Error> = .success(())
    var setPinsResult: Result<Void, Error> = .success(())
    var setVaultTimeoutError: Error?
    var unlockVaultFromLoginWithDeviceKey: String?
    var unlockVaultFromLoginWithDeviceMasterPasswordHash: String? // swiftlint:disable:this identifier_name
    var unlockVaultFromLoginWithDevicePrivateKey: String?
    var unlockVaultFromLoginWithDeviceResult: Result<Void, Error> = .success(())
    var unlockVaultPassword: String?
    var unlockVaultPIN: String?
    var unlockWithPasswordResult: Result<Void, Error> = .success(())
    var unlockWithPINResult: Result<Void, Error> = .success(())

    var unlockVaultResult: Result<Void, Error> = .success(())
    var unlockVaultWithBiometricsResult: Result<Void, Error> = .success(())
    var unlockVaultWithDeviceKeyResult: Result<Void, Error> = .success(())
    var unlockVaultWithNeverlockResult: Result<Void, Error> = .success(())
    var verifyOtpOpt: String?
    var verifyOtpResult: Result<Void, Error> = .success(())

    var allAccounts: [Account] {
        let combined = [activeAccount] + altAccounts
        return combined.compactMap { $0 }
    }

    var updateMasterPasswordCurrentPassword: String?
    var updateMasterPasswordNewPassword: String?
    var updateMasterPasswordPasswordHint: String?
    var updateMasterPasswordReason: ForcePasswordResetReason?
    var updateMasterPasswordResult: Result<Void, Error> = .success(())

    var validatePasswordPasswords = [String]()
    var validatePasswordResult: Result<Bool, Error> = .success(true)

    var vaultTimeout = [String: SessionTimeoutValue]()

    func allowBioMetricUnlock(_ enabled: Bool) async throws {
        allowBiometricUnlock = enabled
        try allowBiometricUnlockResult.get()
    }

    func clearPins() async throws {
        clearPinsCalled = true
    }

    func createNewSsoUser(orgIdentifier: String, rememberDevice: Bool) async throws {
        createNewSsoUserOrgIdentifier = orgIdentifier
        createNewSsoUserRememberDevice = rememberDevice
        try createNewSsoUserResult.get()
    }

    func deleteAccount(passwordText _: String) async throws {
        deleteAccountCalled = true
    }

    func getAccount(for userId: String?) async throws -> Account {
        if let getAccountError {
            throw getAccountError
        }
        switch (userId, activeAccount) {
        case let (nil, .some(active)):
            return active
        case (nil, nil):
            throw StateServiceError.noActiveAccount
        case let (id, _):
            guard let match = allAccounts.first(where: { $0.profile.userId == id }) else {
                throw StateServiceError.noAccounts
            }
            return match
        }
    }

    func getFingerprintPhrase() async throws -> String {
        try fingerprintPhraseResult.get()
    }

    func getProfilesState(
        allowLockAndLogout: Bool,
        isVisible: Bool,
        shouldAlwaysHideAddAccount: Bool,
        showPlaceholderToolbarIcon: Bool
    ) async -> BitwardenShared.ProfileSwitcherState {
        if let profileSwitcherState {
            return ProfileSwitcherState(
                accounts: profileSwitcherState.accounts,
                activeAccountId: profileSwitcherState.activeAccountId,
                allowLockAndLogout: allowLockAndLogout,
                isVisible: isVisible,
                shouldAlwaysHideAddAccount: shouldAlwaysHideAddAccount,
                showPlaceholderToolbarIcon: showPlaceholderToolbarIcon
            )
        }
        return .empty(
            shouldAlwaysHideAddAccount: shouldAlwaysHideAddAccount
        )
    }

    func hasMasterPassword() async throws -> Bool {
        hasMasterPassword
    }

    func isLocked(userId: String?) async throws -> Bool {
        try isLockedResult.get()
    }

    func isPinUnlockAvailable() async throws -> Bool {
        try isPinUnlockAvailableResult.get()
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

    func requestOtp() async throws {
        requestOtpCalled = true
        try requestOtpResult.get()
    }

    func setActiveAccount(userId: String) async throws -> Account {
        setActiveAccountId = userId
        let priorActive = activeAccount
        if let setActiveAccountError { throw setActiveAccountError }
        guard let match = allAccounts
            .first(where: { $0.profile.userId == userId }) else { throw StateServiceError.noAccounts }
        activeAccount = match
        altAccounts = altAccounts
            .filter { $0.profile.userId == userId }
            + [priorActive].compactMap { $0 }
        return match
    }

    func setPins(_ pin: String, requirePasswordAfterRestart _: Bool) async throws {
        encryptedPin = pin
        pinProtectedUserKey = pin
        try setPinsResult.get()
    }

    func sessionTimeoutAction(userId: String?) async throws -> SessionTimeoutAction {
        let userId = try unwrapUserId(userId)
        return sessionTimeoutAction[userId] ?? .lock
    }

    func sessionTimeoutValue(userId: String?) async throws -> BitwardenShared.SessionTimeoutValue {
        guard let value = try vaultTimeout[unwrapUserId(userId)] else {
            throw (userId == nil)
                ? StateServiceError.noActiveAccount
                : StateServiceError.noAccounts
        }
        return value
    }

    func setMasterPassword(
        _ password: String,
        masterPasswordHint: String,
        organizationId: String,
        organizationIdentifier: String,
        resetPasswordAutoEnroll: Bool
    ) async throws {
        setMasterPasswordHint = masterPasswordHint
        setMasterPasswordPassword = password
        setMasterPasswordOrganizationId = organizationId
        setMasterPasswordOrganizationIdentifier = organizationIdentifier
        setMasterPasswordResetPasswordAutoEnroll = resetPasswordAutoEnroll
        try setMasterPasswordResult.get()
    }

    func setVaultTimeout(value: BitwardenShared.SessionTimeoutValue, userId: String?) async throws {
        try vaultTimeout[unwrapUserId(userId)] = value
        if let setVaultTimeoutError {
            throw setVaultTimeoutError
        }
    }

    func unlockVaultFromLoginWithDevice(privateKey: String, key: String, masterPasswordHash: String?) async throws {
        unlockVaultFromLoginWithDeviceKey = key
        unlockVaultFromLoginWithDevicePrivateKey = privateKey
        unlockVaultFromLoginWithDeviceMasterPasswordHash = masterPasswordHash
        try unlockVaultFromLoginWithDeviceResult.get()
    }

    func unlockVaultWithDeviceKey() async throws {
        try unlockVaultWithDeviceKeyResult.get()
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

    /// Attempts to convert a possible user id into a known account id.
    ///
    /// - Parameter userId: If nil, the active account id is returned. Otherwise, validate the id.
    ///
    func unwrapUserId(_ userId: String?) throws -> String {
        if let userId {
            return userId
        } else if let activeAccount {
            return activeAccount.profile.userId
        } else {
            throw StateServiceError.noActiveAccount
        }
    }

    func updateMasterPassword(
        currentPassword: String,
        newPassword: String,
        passwordHint: String,
        reason: ForcePasswordResetReason
    ) async throws {
        updateMasterPasswordCurrentPassword = currentPassword
        updateMasterPasswordNewPassword = newPassword
        updateMasterPasswordPasswordHint = passwordHint
        updateMasterPasswordReason = reason
        return try updateMasterPasswordResult.get()
    }

    func validatePassword(_ password: String) async throws -> Bool {
        validatePasswordPasswords.append(password)
        return try validatePasswordResult.get()
    }

    func verifyOtp(_ otp: String) async throws {
        verifyOtpOpt = otp
        try verifyOtpResult.get()
    }
}
