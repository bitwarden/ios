import Foundation

@testable import AuthenticatorBridgeKit

extension AuthenticatorBridgeItemDataModel {
    static func fixture(
        favorite: Bool = false,
        id: String = UUID().uuidString,
        name: String = "Name",
        totpKey: String? = nil,
        username: String? = nil
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
            AuthenticatorBridgeItemDataModel.fixture(favorite: true),
            AuthenticatorBridgeItemDataModel.fixture(totpKey: "TOTP Key"),
            AuthenticatorBridgeItemDataModel.fixture(username: "Username"),
            AuthenticatorBridgeItemDataModel.fixture(totpKey: "TOTP Key", username: "Username"),
            AuthenticatorBridgeItemDataModel.fixture(totpKey: ""),
            AuthenticatorBridgeItemDataModel.fixture(username: ""),
            AuthenticatorBridgeItemDataModel.fixture(totpKey: "", username: ""),
        ]
    }
}
