import BitwardenSdk

/// Extensions for the `BitwardenSdk.CipherView`
extension CipherView {
    /// Whether the cipher has Fido2 credentials or not
    var hasFido2Credentials: Bool {
        guard type == .login, let login else {
            return false
        }
        return login.hasFido2Credentials
    }

    /// The main Fido2 credenital of the login, if exists.
    var mainFido2Credential: Fido2CredentialView? {
        guard let login else {
            return nil
        }
        return login.mainFido2Credential
    }

    /// What should be used as username of the main Fido2 credential, if exists.
    var mainFido2CredentialUsername: String {
        let fido2Username = mainFido2Credential?.userName
        let result = fido2Username
            .fallbackOnWhitespaceOrNil(fallback: mainFido2Credential?.userDisplayName)
            .fallbackOnWhitespaceOrNil(fallback: login?.username)
            .fallbackOnWhitespaceOrNil(fallback: name)
            .fallbackOnWhitespaceOrNil(fallback: Localizations.unknownAccount)
        return result!
    }
}
