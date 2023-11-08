import BitwardenSdk

@testable import BitwardenShared

extension VaultListItem {
    static func fixture(
        cipherListView: CipherListView = .fixture()
    ) -> VaultListItem {
        VaultListItem(cipherListView: cipherListView)!
    }
}
