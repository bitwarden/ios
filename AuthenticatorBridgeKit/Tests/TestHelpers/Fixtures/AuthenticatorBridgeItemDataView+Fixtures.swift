import Foundation

@testable import AuthenticatorBridgeKit

extension AuthenticatorBridgeItemDataView {
    static func fixture(
        bitwardenAccountDomain: String? = "",
        bitwardenAccountEmail: String? = "",
        favorite: Bool = false,
        id: String = UUID().uuidString,
        name: String = "Name",
        totpKey: String? = nil,
        username: String? = nil
    ) -> AuthenticatorBridgeItemDataView {
        AuthenticatorBridgeItemDataView(
            bitwardenAccountDomain: bitwardenAccountDomain,
            bitwardenAccountEmail: bitwardenAccountEmail,
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
            AuthenticatorBridgeItemDataView.fixture(bitwardenAccountDomain: "https://vault.example.com"),
            AuthenticatorBridgeItemDataView.fixture(bitwardenAccountEmail: "bw@example.com"),
            AuthenticatorBridgeItemDataView.fixture(totpKey: "TOTP Key"),
            AuthenticatorBridgeItemDataView.fixture(username: "Username"),
            AuthenticatorBridgeItemDataView.fixture(totpKey: "TOTP Key", username: "Username"),
            AuthenticatorBridgeItemDataView.fixture(bitwardenAccountEmail: ""),
            AuthenticatorBridgeItemDataView.fixture(totpKey: ""),
            AuthenticatorBridgeItemDataView.fixture(username: ""),
            AuthenticatorBridgeItemDataView.fixture(totpKey: "", username: ""),
        ]
    }
}
