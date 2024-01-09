import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension VaultListItem {
    static func fixture(
        cipherListView: CipherListView = .fixture()
    ) -> VaultListItem {
        VaultListItem(cipherListView: cipherListView)!
    }

    static func fixtureGroup(
        id: String = "123",
        group: VaultListGroup = .card,
        count: Int = 1
    ) -> VaultListItem {
        VaultListItem(
            id: id,
            itemType: .group(
                group,
                count
            )
        )
    }

    static func fixtureTOTP(
        name: String = "Name",
        totp: VaultListTOTP = .fixture()
    ) -> VaultListItem {
        VaultListItem(id: totp.id, itemType: .totp(name: name, totpModel: totp))
    }
}

extension VaultListTOTP {
    static func fixture(
        iconBaseURL: URL = URL(string: "https://icons.bitwarden.net")!,
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
