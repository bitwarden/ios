// swiftlint:disable:this file_name

import AuthenticationServices
import BitwardenSdk

// MARK: - GetAssertionRequest

extension GetAssertionRequest {
    /// Initializes a `GetAssertionRequest` based on `fido2RequestParameters`
    /// - Parameter fido2RequestParameters: The Fido2 request parameters.
    init(fido2RequestParameters: PasskeyCredentialRequestParameters) {
        self = .init(
            rpId: fido2RequestParameters.relyingPartyIdentifier,
            clientDataHash: fido2RequestParameters.clientDataHash,
            allowList: fido2RequestParameters.allowedCredentials.map { credentialId in
                PublicKeyCredentialDescriptor(
                    ty: "public-key",
                    id: credentialId,
                    transports: nil
                )
            },
            options: Options(
                rk: false,
                uv: BitwardenSdk.Uv(preference: fido2RequestParameters.userVerificationPreference)
            ),
            extensions: nil
        )
    }

    /// Initializes a `GetAssertionRequest` based on `passkeyRequest` and its `credentialIdentity`
    /// - Parameters:
    ///   - passkeyRequest: The `ASPasskeyCredentialRequest` of the flow.
    ///   - credentialIdentity: The `ASPasskeyCredentialIdentity` of the request.
    @available(iOSApplicationExtension 17.0, *)
    init(passkeyRequest: ASPasskeyCredentialRequest, credentialIdentity: ASPasskeyCredentialIdentity) {
        self = .init(
            rpId: credentialIdentity.relyingPartyIdentifier,
            clientDataHash: passkeyRequest.clientDataHash,
            allowList: [
                PublicKeyCredentialDescriptor(
                    ty: "public-key",
                    id: credentialIdentity.credentialID,
                    transports: nil
                ),
            ],
            options: Options(
                rk: false,
                uv: BitwardenSdk.Uv(preference: passkeyRequest.userVerificationPreference)
            ),
            extensions: createExtensionJson(passkeyRequest: passkeyRequest),
        )
    }
}

@available(iOSApplicationExtension 17.0, *)
private func createExtensionJson(passkeyRequest: ASPasskeyCredentialRequest) -> String? {
    guard #available(iOSApplicationExtension 18.0, *) else {
        return nil
    }
    let prf: (Data, Data?)? = switch passkeyRequest.extensionInput {
    case let .assertion(ext):
        if let input = ext.prf?.inputValues {
            (input.saltInput1, input.saltInput2)
        }
        else {
            nil
        }
    case let .registration(ext):
        if let input = ext.prf?.inputValues {
            (input.saltInput1, input.saltInput2)
        }
        else {
            nil
        }
    default:
        nil
    }
    guard let prf else { return nil }
    
    let encoder = JSONEncoder()
    let salt2 = if let salt2 = prf.1 {
        "\"" + salt2.base64UrlEncodedString(trimPadding: true) + "\""
    }
    else { "null" }
    let eval = #"""
        {
            "first": "\#(prf.0.base64UrlEncodedString(trimPadding: true))",
            "second": \#(salt2)
        }
        """#
    return #"{"prf":{"eval":\#(eval)}}"#
}

// MARK: - MakeCredentialRequest

extension BitwardenSdk.MakeCredentialRequest: @retroactive CustomDebugStringConvertible {
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

extension BitwardenSdk.MakeCredentialResult: @retroactive CustomDebugStringConvertible {
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
