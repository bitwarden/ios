import Foundation

@testable import AuthenticatorBridgeKit

extension AuthenticatorBridgeItemDataModel {
    static func fixture(
        favorite: Bool = true,
        id: String = UUID().uuidString,
        name: String = "Name",
        totpKey: String? = "TOTP Key",
        username: String? = "Username"
    ) -> AuthenticatorBridgeItemDataModel {
        AuthenticatorBridgeItemDataModel(
            favorite: favorite,
            id: id,
            name: name,
            totpKey: totpKey,
            username: username
        )
    }

    static func fixtures() -> [AuthenticatorBridgeItemDataModel] {
        [
            AuthenticatorBridgeItemDataModel.fixture(),
            AuthenticatorBridgeItemDataModel.fixture(favorite: false),
            AuthenticatorBridgeItemDataModel.fixture(totpKey: nil),
            AuthenticatorBridgeItemDataModel.fixture(username: nil),
            AuthenticatorBridgeItemDataModel.fixture(totpKey: nil, username: nil),
            AuthenticatorBridgeItemDataModel.fixture(totpKey: ""),
            AuthenticatorBridgeItemDataModel.fixture(username: ""),
            AuthenticatorBridgeItemDataModel.fixture(totpKey: "", username: ""),
        ]
    }
}
