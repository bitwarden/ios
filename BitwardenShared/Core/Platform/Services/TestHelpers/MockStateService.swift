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

    func getAccountEncryptionKeys() async throws -> AccountEncryptionKeys {
        guard let activeAccount,
              let encryptionKeys = accountEncryptionKeys[activeAccount.profile.userId]
        else {
            throw StateServiceError.noActiveAccount
        }
        return encryptionKeys
    }

    func getActiveAccount() async throws -> Account {
        guard let activeAccount else { throw StateServiceError.noActiveAccount }
        return activeAccount
    }

    func logoutAccount(_ userId: String) async {
        accountsLoggedOut.append(userId)
    }

    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys) async throws {
        guard let activeAccount else { throw StateServiceError.noActiveAccount }
        accountEncryptionKeys[activeAccount.profile.userId] = encryptionKeys
    }

    func setTokens(accessToken: String, refreshToken: String) async throws {
        accountTokens = Account.AccountTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
}
