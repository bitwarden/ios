import BitwardenSdk
import Foundation

@testable import AuthenticatorShared

extension ItemListItem {
    static func fixture(
        id: String = "123",
        name: String = "Name",
        token: Token = Token(
            name: "Name",
            authenticatorKey: "example"
        )!,
        totpCode: TOTPCodeModel = TOTPCodeModel(
            code: "123456",
            codeGenerationDate: .now,
            period: 30
        )
    ) -> ItemListItem {
        ItemListItem(id: id, name: name, token: token, totpCode: totpCode)
    }
}
