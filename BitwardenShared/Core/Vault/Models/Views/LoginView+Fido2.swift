// swiftlint:disable:this file_name

import BitwardenSdk

/// Extensions for the `BitwardenSdk.LoginView`
extension BitwardenSdk.LoginView {
    /// Whether the login has Fido2 credentials or not
    var hasFido2Credentials: Bool {
        guard let fido2Credentials else {
            return false
        }

        return !fido2Credentials.isEmpty
    }

    /// The main (first) Fido2 credential which is the only one we may have.
    /// Note: currently, there may be up to one Fido2 credential in the array,
    /// so normally we should interact with the credential using this.
    var mainFido2Credential: Fido2CredentialView? {
        fido2Credentials?[0]
    }
}
