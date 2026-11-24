import BitwardenResources
import Testing

@testable import BitwardenShared

// MARK: - VaultAutofillListStateTests

struct VaultAutofillListStateTests {
    // MARK: Tests

    /// `isChoosingLoginToUpdatePassword` is `true` only when the list is limited to the logins to
    /// update with the password from a save-password request.
    @Test
    func isChoosingLoginToUpdatePassword() {
        #expect(!VaultAutofillListState().isChoosingLoginToUpdatePassword)
        #expect(VaultAutofillListState(savePasswordLoginIds: ["1"]).isChoosingLoginToUpdatePassword)
    }

    /// `navigationTitle` asks which login to update when choosing a login to update, and otherwise
    /// shows the group's title, or "Items" without a group.
    @Test
    func navigationTitle() {
        #expect(VaultAutofillListState().navigationTitle == Localizations.items)
        #expect(VaultAutofillListState(group: .identity).navigationTitle == VaultListGroup.identity.navigationTitle)
        #expect(VaultAutofillListState(savePasswordLoginIds: ["1"]).navigationTitle == Localizations.updateWhichLogin)
    }
}
