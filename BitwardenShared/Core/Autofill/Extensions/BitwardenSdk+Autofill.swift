// swiftlint:disable:this file_name

import AuthenticationServices
import BitwardenSdk

// MARK: - GetAssertionRequest

extension GetAssertionRequest {
    /// Initializes a `GetAssertionRequest` based on `fido2RequestParameters`
    /// - Parameter fido2RequestParameters: The Fido2 request parameters.
    init(fido2RequestParameters: PasskeyCredentialRequestParameters) {
        let extensions: GetAssertionExtensionsInput? = if
            #available(iOSApplicationExtension 18.0, *),
            let extInput = fido2RequestParameters.extensionInput {
            GetAssertionExtensionsInput(passkeyExtensionInput: extInput)
        } else { nil }

        self = .init(
            rpId: fido2RequestParameters.relyingPartyIdentifier,
            clientDataHash: fido2RequestParameters.clientDataHash,
            allowList: fido2RequestParameters.allowedCredentials.map { credentialId in
                PublicKeyCredentialDescriptor(
                    ty: "public-key",
                    id: credentialId,
                    transports: nil,
                )
            },
            options: Options(
                rk: false,
                uv: BitwardenSdk.Uv(preference: fido2RequestParameters.userVerificationPreference),
            ),
            extensions: extensions
        )
    }

    /// Initializes a `GetAssertionRequest` based on `passkeyRequest` and its `credentialIdentity`
    /// - Parameters:
    ///   - passkeyRequest: The `ASPasskeyCredentialRequest` of the flow.
    ///   - credentialIdentity: The `ASPasskeyCredentialIdentity` of the request.
    @available(iOSApplicationExtension 17.0, *)
    init(passkeyRequest: ASPasskeyCredentialRequest, credentialIdentity: ASPasskeyCredentialIdentity) {
        let extensions: GetAssertionExtensionsInput? = if
            #available(iOSApplicationExtension 18.0, *),
            case let .assertion(extInput) = passkeyRequest.extensionInput {
            GetAssertionExtensionsInput(passkeyExtensionInput: extInput)
        } else {
            nil
        }
        self = .init(
            rpId: credentialIdentity.relyingPartyIdentifier,
            clientDataHash: passkeyRequest.clientDataHash,
            allowList: [
                PublicKeyCredentialDescriptor(
                    ty: "public-key",
                    id: credentialIdentity.credentialID,
                    transports: nil,
                ),
            ],
            options: Options(
                rk: false,
                uv: BitwardenSdk.Uv(preference: passkeyRequest.userVerificationPreference),
            ),
            extensions: extensions
        )
    }
}

// MARK: - ASPasskeyAssertionCredential

@available(iOS 17.0, *)
extension ASPasskeyAssertionCredential {
    convenience init(assertionResult: GetAssertionResult, rpId: String, clientDataHash: Data) {
        if #available(iOSApplicationExtension 18.0, *) {
            self.init(
                userHandle: assertionResult.userHandle,
                relyingParty: rpId,
                signature: assertionResult.signature,
                clientDataHash: clientDataHash,
                authenticatorData: assertionResult.authenticatorData,
                credentialID: assertionResult.credentialId,
                extensionOutput: assertionResult.extensions.toNative()
            )
        } else {
            self.init(
                userHandle: assertionResult.userHandle,
                relyingParty: rpId,
                signature: assertionResult.signature,
                clientDataHash: clientDataHash,
                authenticatorData: assertionResult.authenticatorData,
                credentialID: assertionResult.credentialId
            )
        }
    }
}

// MARK: - MakeCredentialRequest

extension BitwardenSdk.MakeCredentialRequest: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        let rpName = rp.name ?? "nil"
        let excludeList = excludeList?.description ?? "nil"
        // TODO: !!
        let extensions = if extensions == nil { "nil" } else { "MakeCredentialExtensionsInput { ... } " }

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
