import Foundation

@testable import AuthenticatorBridgeKit

extension AuthenticatorBridgeItemDataView {
    static func fixture(
        bitwardenAccountName: String? = "",
        favorite: Bool = false,
        id: String = UUID().uuidString,
        name: String = "Name",
        totpKey: String? = nil,
        username: String? = nil
    ) -> AuthenticatorBridgeItemDataView {
        AuthenticatorBridgeItemDataView(
            bitwardenAccountName: bitwardenAccountName,
            favorite: favorite,
            id: id,
            name: name,
            totpKey: totpKey,
            username: username
        )
    }

    static func fixtures() -> [AuthenticatorBridgeItemDataView] {
        [
            AuthenticatorBridgeItemDataView.fixture(),
            AuthenticatorBridgeItemDataView.fixture(favorite: true),
            AuthenticatorBridgeItemDataView.fixture(bitwardenAccountName: "BW Account Name"),
            AuthenticatorBridgeItemDataView.fixture(totpKey: "TOTP Key"),
            AuthenticatorBridgeItemDataView.fixture(username: "Username"),
            AuthenticatorBridgeItemDataView.fixture(totpKey: "TOTP Key", username: "Username"),
            AuthenticatorBridgeItemDataView.fixture(bitwardenAccountName: ""),
            AuthenticatorBridgeItemDataView.fixture(totpKey: ""),
            AuthenticatorBridgeItemDataView.fixture(username: ""),
            AuthenticatorBridgeItemDataView.fixture(totpKey: "", username: ""),
        ]
    }
}
