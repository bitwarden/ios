@testable import BitwardenShared

class MockStateService: StateService {
    var accountsAdded = [Account]()
    var accountsLoggedOut = [String]()

    func addAccount(_ account: BitwardenShared.Account) async {
        accountsAdded.append(account)
    }

    func logoutAccount(_ userId: String) async {
        accountsLoggedOut.append(userId)
    }
}
