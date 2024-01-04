import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension VaultListItem {
    static func fixture(
        cipherListView: CipherListView = .fixture()
    ) -> VaultListItem {
        VaultListItem(cipherListView: cipherListView)!
    }

    static func fixtureTOTP(
        totp: VaultListTOTP = .fixture()
    ) -> VaultListItem {
        VaultListItem(id: totp.id, itemType: .totp(totp))
    }
}

extension VaultListTOTP {
    static func fixture(
        iconBaseURL: URL? = nil,
        id: String = "123",
        loginView: BitwardenSdk.LoginView = .fixture(totp: .base32Key),
        totpCode: TOTPCode = .init(code: "123456", date: Date(), period: 30)
    ) -> VaultListTOTP {
        VaultListTOTP(
            iconBaseURL: iconBaseURL,
            id: id,
            loginView: loginView,
            totpCode: totpCode
        )
    }
}
