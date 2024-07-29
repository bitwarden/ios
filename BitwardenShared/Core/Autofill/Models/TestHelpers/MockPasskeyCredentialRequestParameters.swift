import AuthenticationServices

@testable import BitwardenShared

/// Mock for `PasskeyCredentialRequestParameters` given that
/// we cannot create an instance of `ASPasskeyCredentialRequestParameters`
class MockPasskeyCredentialRequestParameters: PasskeyCredentialRequestParameters {
    var relyingPartyIdentifier: String

    var clientDataHash: Data

    var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference

    var allowedCredentials: [Data]

    init(
        relyingPartyIdentifier: String = "myApp.com",
        clientDataHash: Data = Data(repeating: 1, count: 32),
        userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference = .preferred,
        allowedCredentials: [Data] = []
    ) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.clientDataHash = clientDataHash
        self.userVerificationPreference = userVerificationPreference
        self.allowedCredentials = allowedCredentials
    }
}
