import BitwardenSdk
import Foundation

extension MakeCredentialResult {
    static func fixture(
        attestationObject: Data = Data([0x01]),
        authenticatorData: Data = Data([0x02]),
        credentialId: Data = Data([0x03]),
    ) -> MakeCredentialResult {
        MakeCredentialResult(
            authenticatorData: authenticatorData,
            attestationObject: attestationObject,
            credentialId: credentialId,
            extensions: MakeCredentialExtensionsOutput(prf: nil),
        )
    }
}
