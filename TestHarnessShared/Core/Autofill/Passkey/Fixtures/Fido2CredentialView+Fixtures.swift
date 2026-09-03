import BitwardenSdk
import Foundation

extension Fido2CredentialView {
    static func fixture(
        credentialId: String = "credential-id",
        rpId: String = "bitwarden.com",
        userName: String? = "user@example.com",
    ) -> Fido2CredentialView {
        Fido2CredentialView(
            credentialId: credentialId,
            keyType: "public-key",
            keyAlgorithm: "ECDSA",
            keyCurve: "P-256",
            keyValue: "keyValue",
            rpId: rpId,
            userHandle: nil,
            userName: userName,
            counter: "0",
            rpName: nil,
            userDisplayName: nil,
            discoverable: "true",
            creationDate: Date(timeIntervalSince1970: 0),
        )
    }
}
