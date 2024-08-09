// swiftlint:disable:this file_name

import AuthenticationServices
import BitwardenSdk

// MARK: - MakeCredentialRequest

extension BitwardenSdk.MakeCredentialRequest: CustomDebugStringConvertible {
    public var debugDescription: String {
        let rpName = rp.name ?? "nil"
        let excludeList = excludeList?.description ?? "nil"
        let extensions = extensions?.description ?? "nil"

        return [
            "ClientDataHash: \(clientDataHash.asHexString())",
            "RP -> Id: \(rp.id)",
            "RP -> Name: \(rpName)",
            "User -> Id: \(user.id.asHexString())",
            "User -> Name: \(user.name)",
            "User -> DisplayName: \(user.displayName)",
            "PubKeyCredParams: \(pubKeyCredParams.description)",
            "ExcludeList: \(excludeList)",
            "Options -> RK: \(options.rk)",
            "Options -> UV: \(String(describing: options.uv))",
            "Extensions: \(extensions)",
        ].joined(separator: "\n")
    }
}

// MARK: - MakeCredentialResult

extension BitwardenSdk.MakeCredentialResult: CustomDebugStringConvertible {
    public var debugDescription: String {
        [
            "AuthenticatorData: \(authenticatorData.asHexString())",
            "AttestationObject: \(attestationObject.asHexString())",
            "CredentialId: \(credentialId.asHexString())",
        ].joined(separator: "\n")
    }
}

// MARK: - Uv

extension BitwardenSdk.Uv {
    init(preference: ASAuthorizationPublicKeyCredentialUserVerificationPreference) {
        switch preference {
        case ASAuthorizationPublicKeyCredentialUserVerificationPreference.discouraged:
            self = BitwardenSdk.Uv.discouraged
        case ASAuthorizationPublicKeyCredentialUserVerificationPreference.preferred:
            self = BitwardenSdk.Uv.preferred
        case ASAuthorizationPublicKeyCredentialUserVerificationPreference.required:
            self = BitwardenSdk.Uv.required
        default:
            self = BitwardenSdk.Uv.required
        }
    }
}
