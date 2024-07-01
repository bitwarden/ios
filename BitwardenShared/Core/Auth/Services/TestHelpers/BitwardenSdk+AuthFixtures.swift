// swiftlint:disable:this file_name

import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension BitwardenSdk.AuthenticatorAssertionResponse {
    static func fixture(
        clientDataJson: Data = Data(capacity: 37),
        authenticatorData: Data = Data(capacity: 37),
        signature: Data = Data(capacity: 64),
        userHandle: Data = Data(capacity: 64)
    ) -> BitwardenSdk.AuthenticatorAssertionResponse {
        .init(
            clientDataJson: clientDataJson,
            authenticatorData: authenticatorData,
            signature: signature,
            userHandle: userHandle
        )
    }
}

extension BitwardenSdk.AuthenticatorAttestationResponse {
    static func fixture(
        clientDataJson: Data = Data(capacity: 37),
        authenticatorData: Data = Data(capacity: 37),
        publicKey: Data? = nil,
        publicKeyAlgorithm: Int64 = -7,
        attestationObject: Data = Data(capacity: 64),
        transports: [String]? = nil
    ) -> BitwardenSdk.AuthenticatorAttestationResponse {
        .init(
            clientDataJson: clientDataJson,
            authenticatorData: authenticatorData,
            publicKey: publicKey,
            publicKeyAlgorithm: publicKeyAlgorithm,
            attestationObject: attestationObject,
            transports: transports
        )
    }
}

extension BitwardenSdk.ClientExtensionResults {
    static func fixture(
        credProps: BitwardenSdk.CredPropsResult? = nil
    ) -> BitwardenSdk.ClientExtensionResults {
        .init(credProps: credProps)
    }
}

extension BitwardenSdk.GetAssertionResult {
    static func fixture(
        credentialId: Data = Data(capacity: 16),
        authenticatorData: Data = Data(capacity: 37),
        signature: Data = Data(capacity: 64),
        userHandle: Data = Data(capacity: 64),
        selectedCredential: SelectedCredential = .fixture()
    ) -> BitwardenSdk.GetAssertionResult {
        .init(
            credentialId: credentialId,
            authenticatorData: authenticatorData,
            signature: signature,
            userHandle: userHandle,
            selectedCredential: selectedCredential
        )
    }
}

extension BitwardenSdk.MakeCredentialResult {
    static func fixture(
        authenticatorData: Data = Data(capacity: 37),
        attestedCredentialData: Data = Data(capacity: 37),
        credentialId: Data = Data(capacity: 16)
    ) -> BitwardenSdk.MakeCredentialResult {
        .init(
            authenticatorData: authenticatorData,
            attestedCredentialData: attestedCredentialData,
            credentialId: credentialId
        )
    }
}

extension BitwardenSdk.PublicKeyCredentialAuthenticatorAssertionResponse {
    static func fixture(
        id: String = "1",
        rawId: Data = Data(capacity: 16),
        type: String = "webauthn.get",
        authenticatorAttachment: String? = nil,
        clientExtensionResults: ClientExtensionResults = .fixture(),
        response: AuthenticatorAssertionResponse = .fixture(),
        selectedCredential: SelectedCredential = .fixture()
    ) -> BitwardenSdk.PublicKeyCredentialAuthenticatorAssertionResponse {
        .init(
            id: id,
            rawId: rawId,
            ty: type,
            authenticatorAttachment: authenticatorAttachment,
            clientExtensionResults: clientExtensionResults,
            response: response,
            selectedCredential: selectedCredential
        )
    }
}

extension BitwardenSdk.PublicKeyCredentialAuthenticatorAttestationResponse {
    static func fixture(
        id: String = "1",
        rawId: Data = Data(capacity: 16),
        type: String = "webauthn.create",
        authenticatorAttachment: String? = nil,
        clientExtensionResults: ClientExtensionResults = .fixture(),
        response: AuthenticatorAttestationResponse = .fixture(),
        selectedCredential: SelectedCredential = .fixture()
    ) -> BitwardenSdk.PublicKeyCredentialAuthenticatorAttestationResponse {
        .init(
            id: id,
            rawId: rawId,
            ty: type,
            authenticatorAttachment: authenticatorAttachment,
            clientExtensionResults: clientExtensionResults,
            response: response,
            selectedCredential: selectedCredential
        )
    }
}

extension BitwardenSdk.SelectedCredential {
    static func fixture(
        cipherView: CipherView = .fixture(),
        credential: Fido2CredentialView = .fixture()
    ) -> BitwardenSdk.SelectedCredential {
        .init(cipher: .fixture(), credential: .fixture())
    }
}

extension BitwardenSdk.Fido2CredentialAutofillView {
    static let defaultRpId = "myApp.com"

    static func fixture(
        credentialId: Data = Data(capacity: 16),
        cipherId: String = "1",
        rpId: String = defaultRpId,
        userNameForUi: String? = nil,
        userHandle: Data = Data(capacity: 64)
    ) -> BitwardenSdk.Fido2CredentialAutofillView {
        .init(
            credentialId: credentialId,
            cipherId: cipherId,
            rpId: rpId,
            userNameForUi: userNameForUi,
            userHandle: userHandle
        )
    }
}

extension BitwardenSdk.Fido2CredentialNewView {
    static let defaultRpId = "myApp.com"

    static func fixture(
        credentialId: String = "",
        keyType: String = "",
        keyAlgorithm: String = "",
        keyCurve: String = "",
        rpId: String = defaultRpId,
        userHandle: Data? = nil,
        userName: String? = nil,
        counter: String = "0",
        rpName: String? = nil,
        userDisplayName: String? = nil,
        discoverable: String = "",
        creationDate: DateTime = DateTime.distantPast
    ) -> BitwardenSdk.Fido2CredentialNewView {
        .init(
            credentialId: credentialId,
            keyType: keyType,
            keyAlgorithm: keyAlgorithm,
            keyCurve: keyCurve,
            rpId: rpId,
            userHandle: userHandle,
            userName: userName,
            counter: counter,
            rpName: rpName,
            userDisplayName: userDisplayName,
            discoverable: discoverable,
            creationDate: creationDate
        )
    }
}
