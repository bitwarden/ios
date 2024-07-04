// swiftlint:disable:this file_name

import AuthenticationServices

@testable import BitwardenShared

extension ASCredentialServiceIdentifier {
    static func fixture(
        identifier: String = "id",
        type: ASCredentialServiceIdentifier.IdentifierType = ASCredentialServiceIdentifier.IdentifierType.URL
    ) -> ASCredentialServiceIdentifier {
        ASCredentialServiceIdentifier(identifier: identifier, type: type)
    }
}

@available(iOS 17.0, *)
extension ASPasskeyCredentialIdentity {
    static func fixture(
        relyingPartyIdentifier: String = "",
        userName: String = "",
        credentialID: Data = Data(capacity: 32),
        userHandle: Data = Data(capacity: 32),
        recordIdentifier: String? = nil
    ) -> ASPasskeyCredentialIdentity {
        ASPasskeyCredentialIdentity(
            relyingPartyIdentifier: relyingPartyIdentifier,
            userName: userName,
            credentialID: credentialID,
            userHandle: userHandle,
            recordIdentifier: recordIdentifier
        )
    }
}

@available(iOS 17.0, *)
extension ASPasskeyCredentialRequest {
    static func fixture(
        credentialIdentity: ASPasskeyCredentialIdentity = .fixture(),
        clientDataHash: Data = Data(capacity: 32),
        userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference = .discouraged,
        supportedAlgorithms: [ASCOSEAlgorithmIdentifier] = []
    ) -> ASPasskeyCredentialRequest {
        ASPasskeyCredentialRequest(
            credentialIdentity: credentialIdentity,
            clientDataHash: clientDataHash,
            userVerificationPreference: userVerificationPreference,
            supportedAlgorithms: supportedAlgorithms
        )
    }
}

extension ASPasswordCredentialIdentity {
     static func fixture(
        serviceIdentifier: ASCredentialServiceIdentifier = .fixture(),
        user: String = "",
        recordIdentifier: String? = nil
    ) -> ASPasswordCredentialIdentity {
        ASPasswordCredentialIdentity(
            serviceIdentifier: serviceIdentifier,
            user: user,
            recordIdentifier: recordIdentifier
        )
    }
}
