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

    /// The main (first) FIdo2 credential which is the one we
    var mainFido2Credential: Fido2CredentialView? {
        guard hasFido2Credentials else { return nil }
        return fido2Credentials![0]
    }
}
