import Foundation

@testable import BitwardenShared

class MockAuthRepository: AuthRepository { // swiftlint:disable:this type_body_length
    var allowBiometricUnlock: Bool?
    var allowBiometricUnlockResult: Result<Void, Error> = .success(())
    var accountForItemResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var canActiveAccountBeLockedResult: Bool = true
    var canBeLockedResult: [String: Bool] = [:]
    var canVerifyMasterPasswordResult: Result<Bool, Error> = .success(true)
    var canVerifyMasterPasswordForUserResult: Result<[String: Bool], Error> = .success([:])
    var checkSessionTimeoutCalled = false
    var clearPinsCalled = false
    var createNewSsoUserRememberDevice: Bool = false
    var createNewSsoUserOrgIdentifier: String = ""
    var createNewSsoUserResult: Result<Void, Error> = .success(())
    var deleteAccountCalled = false
    var deleteAccountResult: Result<Void, Error> = .success(())
    var deviceId: String = ""
    var email: String = ""
    var encryptedPin: String = "123"
    var existingAccountUserIdEmail: String?
    var existingAccountUserIdResult: String?
    var fingerprintPhraseResult: Result<String, Error> = .success("fingerprint")
    var activeAccount: Account?
    var altAccounts = [Account]()
    var getAccountError: Error?
    var getSSOOrganizationIdentifierByResult: Result<String?, Error> = .success(nil)
    var handleActiveUserClosure: ((String) async -> Void)?
    var hasManuallyLocked = false
    var hasMasterPasswordResult = Result<Bool, Error>.success(true)
    var isLockedResult: Result<Bool, Error> = .success(true)
    var isPinUnlockAvailableResult: Result<Bool, Error> = .success(false)
    var isUserManagedByOrganizationResult: Result<Bool, Error> = .success(false)
    var pinUnlockAvailabilityResult: Result<[String: Bool], Error> = .success([:])
    var lockVaultUserId: String?
    var logoutCalled = false
    var logoutUserId: String?
    var logoutUserInitiated = false
    var logoutResult: Result<Void, Error> = .success(())
    var migrateUserToKeyConnectorCalled = false
    var migrateUserToKeyConnectorPassword: String?
    var migrateUserToKeyConnectorResult: Result<Void, Error> = .success(())
    var passwordStrengthEmail: String?
    var passwordStrengthIsPreAuth = false
    var passwordStrengthPassword: String?
    var passwordStrengthResult: Result<UInt8, Error> = .success(0)
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
    var setPinsRequirePasswordAfterRestart: Bool?
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
    var unlockVaultWithAuthVaultKeyCalled = false
    var unlockVaultWithAuthVaultKeyResult: Result<Void, Error> = .success(())
    var unlockVaultWithDeviceKeyCalled = false
    var unlockVaultWithDeviceKeyResult: Result<Void, Error> = .success(())
    var unlockVaultWithKeyConnectorKeyCalled = false
    var unlockVaultWithKeyConnectorKeyConnectorURL: URL? // swiftlint:disable:this identifier_name
    var unlockVaultWithKeyConnectorOrgIdentifier: String?
    var unlockVaultWithKeyConnectorKeyResult: Result<Void, Error> = .success(())
    var unlockVaultWithNeverlockKeyCalled = false
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

    var validatePinResult: Result<Bool, Error> = .success(false)

    var vaultTimeout = [String: SessionTimeoutValue]()

    func allowBioMetricUnlock(_ enabled: Bool) async throws {
        allowBiometricUnlock = enabled
        try allowBiometricUnlockResult.get()
    }

    func canBeLocked(userId: String?) async -> Bool {
        if let userId {
            canBeLockedResult[userId] ?? false
        } else {
            canActiveAccountBeLockedResult
        }
    }

    func canVerifyMasterPassword() async throws -> Bool {
        try canVerifyMasterPasswordResult.get()
    }

    func canVerifyMasterPassword(userId: String?) async throws -> Bool {
        if let userId {
            try canVerifyMasterPasswordForUserResult.get()[userId] ?? false
        } else {
            try canVerifyMasterPasswordResult.get()
        }
    }

    func checkSessionTimeouts(handleActiveUser: ((String) async -> Void)?) async {
        checkSessionTimeoutCalled = true
        handleActiveUserClosure = handleActiveUser
    }

    func clearPins() async throws {
        clearPinsCalled = true
    }

    func createNewSsoUser(orgIdentifier: String, rememberDevice: Bool) async throws {
        createNewSsoUserOrgIdentifier = orgIdentifier
        createNewSsoUserRememberDevice = rememberDevice
        try createNewSsoUserResult.get()
    }

    func deleteAccount(otp: String?, passwordText _: String?) async throws {
        deleteAccountCalled = true
        try deleteAccountResult.get()
    }

    func existingAccountUserId(email: String) async -> String? {
        existingAccountUserIdEmail = email
        return existingAccountUserIdResult
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

    func getSingleSignOnOrganizationIdentifier(email: String) async throws -> String? {
        try getSSOOrganizationIdentifierByResult.get()
    }

    func hasMasterPassword() async throws -> Bool {
        try hasMasterPasswordResult.get()
    }

    func isLocked(userId: String?) async throws -> Bool {
        try isLockedResult.get()
    }

    func isPinUnlockAvailable() async throws -> Bool {
        try isPinUnlockAvailableResult.get()
    }

    func isPinUnlockAvailable(userId: String?) async throws -> Bool {
        if let userId {
            try pinUnlockAvailabilityResult.get()[userId] ?? false
        } else {
            try isPinUnlockAvailableResult.get()
        }
    }

    func isUserManagedByOrganization() async throws -> Bool {
        try isUserManagedByOrganizationResult.get()
    }

    func passwordStrength(email: String, password: String, isPreAuth: Bool) async throws -> UInt8 {
        passwordStrengthEmail = email
        passwordStrengthPassword = password
        passwordStrengthIsPreAuth = isPreAuth
        return try passwordStrengthResult.get()
    }

    func lockVault(userId: String?, isManuallyLocking: Bool) async {
        lockVaultUserId = userId
        hasManuallyLocked = isManuallyLocking
    }

    func logout(userId: String?, userInitiated: Bool) async throws {
        logoutUserId = userId
        logoutUserInitiated = userInitiated
        try await logout()
    }

    func logout() async throws {
        logoutCalled = true
        try logoutResult.get()
    }

    func migrateUserToKeyConnector(password: String) async throws {
        migrateUserToKeyConnectorCalled = true
        migrateUserToKeyConnectorPassword = password
        return try migrateUserToKeyConnectorResult.get()
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

    func setPins(_ pin: String, requirePasswordAfterRestart: Bool) async throws {
        encryptedPin = pin
        pinProtectedUserKey = pin
        setPinsRequirePasswordAfterRestart = requirePasswordAfterRestart
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

    func unlockVaultWithAuthenticatorVaultKey(userId: String) async throws {
        unlockVaultWithAuthVaultKeyCalled = true
        try unlockVaultWithAuthVaultKeyResult.get()
    }

    func unlockVaultWithDeviceKey() async throws {
        unlockVaultWithDeviceKeyCalled = true
        try unlockVaultWithDeviceKeyResult.get()
    }

    func unlockVaultWithKeyConnectorKey(keyConnectorURL: URL, orgIdentifier: String) async throws {
        unlockVaultWithKeyConnectorKeyCalled = true
        unlockVaultWithKeyConnectorKeyConnectorURL = keyConnectorURL
        unlockVaultWithKeyConnectorOrgIdentifier = orgIdentifier
        try unlockVaultWithKeyConnectorKeyResult.get()
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
        unlockVaultWithNeverlockKeyCalled = true
        return try unlockVaultWithNeverlockResult.get()
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

    func validatePin(pin: String) async throws -> Bool {
        try validatePinResult.get()
    }

    func verifyOtp(_ otp: String) async throws {
        verifyOtpOpt = otp
        try verifyOtpResult.get()
    }
}
