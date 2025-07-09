import AuthenticatorBridgeKit
import BitwardenSdk
import Foundation

@testable import AuthenticatorShared

extension ItemListSection {
    static func fixture() -> ItemListSection {
        ItemListSection(
            id: "example",
            items: [ItemListItem.fixture()],
            name: "Section"
        )
    }
}

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

    static func fixtureShared(
        id: String = "123",
        name: String = "Name",
        accountName: String? = "person@example.com",
        totp: ItemListSharedTotpItem = .fixture()
    ) -> ItemListItem {
        ItemListItem(
            id: id,
            name: name,
            accountName: accountName,
            itemType: .sharedTotp(model: totp)
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
        )
    ) -> ItemListTotpItem {
        ItemListTotpItem(
            itemView: itemView,
            totpCode: totpCode
        )
    }
}

extension ItemListSharedTotpItem {
    static func fixture(
        itemView: AuthenticatorBridgeItemDataView = .fixtureFilled(),
        totpCode: TOTPCodeModel = TOTPCodeModel(
            code: "123456",
            codeGenerationDate: Date(),
            period: 30
        )
    ) -> ItemListSharedTotpItem {
        ItemListSharedTotpItem(
            itemView: itemView,
            totpCode: totpCode
        )
    }
}
