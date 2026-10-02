import BitwardenSdk
import Foundation

extension GetAssertionResult {
    static func fixture(
        credentialId: Data = Data([0x03]),
        selectedCredential: SelectedCredential = SelectedCredential(cipher: .fixture(), credential: .fixture()),
    ) -> GetAssertionResult {
        GetAssertionResult(
            credentialId: credentialId,
            authenticatorData: Data([0x02]),
            signature: Data([0x04]),
            userHandle: Data([0x05]),
            selectedCredential: selectedCredential,
            extensions: GetAssertionExtensionsOutput(prf: nil),
        )
    }
}
