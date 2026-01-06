import Foundation
import Networking

// swiftlint:disable line_length

// MARK: WebAuthnLoginCredentialCreationOptionsResponse

/// Parameters received from the server to initiate a WebAuthn credential creation flow.
struct WebAuthnLoginCredentialCreationOptionsResponse: JSONResponse, Equatable, Sendable {
    /// Options to be provided to the webauthn authenticator.
    let options: PublicKeyCredentialCreationOptions

    /// Contains an encrypted version of the {@link options}.
    /// Used by the server to validate the attestation response of newly created credentials.
    let token: String
}

// MARK: PublicKeyCredentialCreationOptions

/// WebAuthn [PublicKeyCredentialCreationOptions](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialcreationoptions).
struct PublicKeyCredentialCreationOptions: Codable, Equatable, Hashable {
    /// A base64-encoded challenge that the authenticator signs, along with other data, when producing an attestation
    /// object for the newly created credential.
    ///
    /// ([Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-challenge))
    ///
    /// Note that the server sends this challenge as a padded base64 string, not as a unpadded base64url string as is
    /// used in most places in the WebAuthn spec.
    let challenge: String

    /// Credential IDs received from the server which should not appear on the authenticator used to complete the
    /// ceremony.
    ///
    /// ([Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-excludecredentials))
    let excludeCredentials: [BwPublicKeyCredentialDescriptor]?

    /// WebAuthn client extension inputs.
    ///
    /// ([Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-extensions)).
    let extensions: AuthenticationExtensionsClientInputs?

    /// Types of WebAuthn credentials that the server supports.
    ///
    /// ([Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-pubkeycredparams))
    let pubKeyCredParams: [BwPublicKeyCredentialParameters]

    /// Relying party information for the request.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-rp).
    let rp: BwPublicKeyCredentialRpEntity // swiftlint:disable:this identifier_name

    /// Time, in milliseconds, that the server is willing to wait for a response.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-timeout)
    let timeout: Int?

    /// Information about the user for whom the credential is being created.
    ///
    /// [Link to spec](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-user).
    let user: BwPublicKeyCredentialUserEntity
}

// MARK: AuthenticationExtensionsClientInputs

/// Inputs for WebAuthn extensions.
struct AuthenticationExtensionsClientInputs: Codable, Equatable, Hashable {
    /// Input values for PRF extensions.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-authenticationextensionsclientinputs-prf)
    let prf: AuthenticationExtensionsPRFInputs?
}

// MARK: AuthenticationExtensionsPRFInputs

/// Input values for WebAutn PRF extension.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-authenticationextensionsprfinputs)
struct AuthenticationExtensionsPRFInputs: Codable, Equatable, Hashable {
    let eval: AuthenticationExtensionsPRFValues?
    let evalByCredential: [String: AuthenticationExtensionsPRFValues]?
}

// MARK: AuthenticationExtensionsPRFValues

/// WebAuthn PRF input values.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-authenticationextensionsprfvalues)
struct AuthenticationExtensionsPRFValues: Codable, Equatable, Hashable {
    let first: String
    let second: String?
}

// MARK: BwPublicKeyCredentialDescriptor

/// WebAuthn Credential Descriptor.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictionary-credential-descriptor)
/// Distinct from ``BitwardenSdk.PublicKeyCredentialDescriptor`` for deserialization purposes.
struct BwPublicKeyCredentialDescriptor: Codable, Equatable, Hashable {
    let type: String
    let id: String
}

// MARK: BwPublicKeyCredentialParameters

/// WebAuthn parameters for credential generation.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialparameters)
/// Distinct from ``BitwardenSdk.PublicKeyCredentialParameters`` for serialization purposes.
struct BwPublicKeyCredentialParameters: Codable, Equatable, Hashable {
    let type: String
    let alg: Int
}

// MARK: BwPublicKeyCredentialRpEntity

/// WebAuthn relying party information.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialrpentity)
/// Distinct from ``BitwardenSdk.PublicKeyCredentialRpEntity`` for serialization purposes.
struct BwPublicKeyCredentialRpEntity: Codable, Equatable, Hashable {
    let id: String
    let name: String
}

// MARK: BwPublicKeyCredentialUserEntity

/// WebAuthn user account parameters.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialuserentity)
/// Distinct from ``BitwardenSdk.PublicKeyCredentialUserEntity`` for serialization purposes.
struct BwPublicKeyCredentialUserEntity: Codable, Equatable, Hashable {
    let id: String
    let name: String
}

// swiftlint:enable line_length
