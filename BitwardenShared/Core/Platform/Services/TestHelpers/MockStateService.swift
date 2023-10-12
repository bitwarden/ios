@testable import BitwardenShared

class MockStateService: StateService {
    var accountEncryptionKeys = [String: AccountEncryptionKeys]()
    var accountTokens: Account.AccountTokens?
    var accountsAdded = [Account]()
    var accountsLoggedOut = [String]()
    var activeAccount: Account?

    func addAccount(_ account: BitwardenShared.Account) async {
        accountsAdded.append(account)
    }

    func getAccountEncryptionKeys(userId: String?) async throws -> AccountEncryptionKeys {
        let userId = try userId ?? getActiveAccount().profile.userId
        guard let encryptionKeys = accountEncryptionKeys[userId]
        else {
            throw StateServiceError.noActiveAccount
        }
        return encryptionKeys
    }

    func getActiveAccount() throws -> Account {
        guard let activeAccount else { throw StateServiceError.noActiveAccount }
        return activeAccount
    }

    func logoutAccount(userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        accountsLoggedOut.append(userId)
    }

    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys, userId: String?) async throws {
        let userId = try userId ?? getActiveAccount().profile.userId
        accountEncryptionKeys[userId] = encryptionKeys
    }

    func setTokens(accessToken: String, refreshToken: String, userId: String?) async throws {
        accountTokens = Account.AccountTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
}
