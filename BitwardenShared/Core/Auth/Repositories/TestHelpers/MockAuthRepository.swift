@testable import BitwardenShared

class MockAuthRepository: AuthRepository {
    var accountResult: Result<Account, Error> = .failure(StateServiceError.noAccounts)
    var profileStateResult: Result<ProfileSwitcherState?, Error> = .success(nil)
    var capturedUserId: String?
    var capturedProfileState: ProfileSwitcherState?
    var logoutCalled = false
    var unlockVaultPassword: String?
    var unlockVaultResult: Result<ProfileSwitcherState?, Error> = .success(nil)

    func getAccount(for userId: String?) async throws -> BitwardenShared.Account {
        capturedUserId = userId
        return try accountResult.get()
    }

    func getProfileSwitcherState(
        visible: Bool,
        shouldAlwaysHideAddAccount: Bool
    ) async -> BitwardenShared.ProfileSwitcherState {
        guard let result = try? profileStateResult.get() else {
            var new = ProfileSwitcherState.empty(shouldAlwaysHideAddAccount: shouldAlwaysHideAddAccount)
            new.isVisible = visible
            return new
        }
        return .init(
            accounts: result.accounts,
            activeAccountId: result.activeAccountId,
            isVisible: visible,
            shouldAlwaysHideAddAccount: shouldAlwaysHideAddAccount
        )
    }

    func lockVault(
        userId: String?,
        state: BitwardenShared.ProfileSwitcherState?
    ) async -> BitwardenShared.ProfileSwitcherState? {
        capturedUserId = userId
        capturedProfileState = state
        return try? profileStateResult.get()
    }

    func logout(
        userId: String?,
        state: BitwardenShared.ProfileSwitcherState?
    ) async throws -> BitwardenShared.ProfileSwitcherState? {
        logoutCalled = true
        capturedUserId = userId
        capturedProfileState = state
        return try? profileStateResult.get()
    }

    func setActiveAccount(
        userId: String,
        state: BitwardenShared.ProfileSwitcherState?
    ) async throws -> BitwardenShared.ProfileSwitcherState? {
        capturedUserId = userId
        capturedProfileState = state
        return try profileStateResult.get()
    }

    func unlockVault(
        password: String,
        state: BitwardenShared.ProfileSwitcherState?
    ) async throws -> BitwardenShared.ProfileSwitcherState? {
        unlockVaultPassword = password
        capturedProfileState = state
        return try unlockVaultResult.get()
    }
}
