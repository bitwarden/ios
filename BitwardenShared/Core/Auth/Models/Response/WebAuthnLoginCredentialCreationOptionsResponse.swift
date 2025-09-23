import Networking
import Foundation

struct WebAuthnLoginCredentialCreateOptionsResponse: JSONResponse, Equatable, Sendable {
  /// Options to be provided to the webauthn authenticator.
  let options: PublicKeyCredentialCreationOptions;

  /// Contains an encrypted version of the {@link options}.
  /// Used by the server to validate the attestation response of newly created credentials.
  let token: String;
}

struct PublicKeyCredentialCreationOptions: Codable, Equatable, Hashable {
    // attestation?: AttestationConveyancePreference
    // let authenticatorSelection: AuthenticatorSelectionCriteria?
    let challenge: String
    let excludeCredentials: [PublicKeyCredentialDescriptor]?
    let extensions: AuthenticationExtensionsClientInputs?
    let pubKeyCredParams: [PublicKeyCredentialParameters]
    let rp: PublicKeyCredentialRpEntity
    let timeout: Int?
    let user: PublicKeyCredentialUserEntity
}


struct AuthenticationExtensionsClientInputs: Codable, Equatable, Hashable {
    let prf: AuthenticationExtensionsPRFInputs
}

struct AuthenticationExtensionsPRFInputs: Codable, Equatable, Hashable {
    let eval: AuthenticationExtensionsPRFValues?
    let evalByCredential: [String: AuthenticationExtensionsPRFValues]?
}

struct AuthenticationExtensionsPRFValues: Codable, Equatable, Hashable {
    let first: String
    let second: String?
}

struct PublicKeyCredentialDescriptor: Codable, Equatable, Hashable {
    let type: String
    let id: String
    // let transports: [String]?
}

struct PublicKeyCredentialParameters: Codable, Equatable, Hashable {
    let type: String
    let alg: Int
}

struct PublicKeyCredentialRpEntity: Codable, Equatable, Hashable {
    let id: String
    let name: String
}

struct PublicKeyCredentialUserEntity: Codable, Equatable, Hashable {
    let id: String
    let name: String
}
