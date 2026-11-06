import BitwardenSdk
import Foundation

extension Fido2CredentialAutofillView {
    static func fixture(
        credentialId: Data = Data([0x01]),
        cipherId: String = "cipher-id",
        rpId: String = "bitwarden.com",
        userNameForUi: String? = "user@example.com",
        userHandle: Data = Data([0x02]),
        hasCounter: Bool = false,
    ) -> Fido2CredentialAutofillView {
        Fido2CredentialAutofillView(
            credentialId: credentialId,
            cipherId: cipherId,
            rpId: rpId,
            userNameForUi: userNameForUi,
            userHandle: userHandle,
            hasCounter: hasCounter,
        )
    }
}
