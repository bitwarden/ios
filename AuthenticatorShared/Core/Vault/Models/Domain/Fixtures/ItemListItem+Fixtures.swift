import BitwardenSdk
import Foundation

@testable import AuthenticatorShared

extension ItemListItem {
    static func fixture(
        id: String = "123",
        name: String = "Name",
        accountName: String = "person@example.com",
        totp: ItemListTotpItem = .fixture()
    ) -> ItemListItem {
        ItemListItem(
            id: id,
            name: name,
            accountName: accountName,
            itemType: .totp(model: totp)
        )
    }
}

extension ItemListTotpItem {
    static func fixture(
        itemView: AuthenticatorItemView = .fixture(),
        totpCode: TOTPCodeModel = TOTPCodeModel(
            code: "123456",
            codeGenerationDate: Date(),
            period: 30
        ),
        totpKey: TOTPKeyModel = TOTPKeyModel(
            authenticatorKey: "example"
        )!
    ) -> ItemListTotpItem {
        ItemListTotpItem(
            itemView: itemView,
            totpCode: totpCode,
            totpKey: totpKey
        )
    }
}
