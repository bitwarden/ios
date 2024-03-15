import Foundation

@testable import BitwardenShared

extension CipherLoginModel {
    static func fixture(
        autofillOnPageLoad: Bool? = nil,
        fido2Credentials: [CipherLoginFido2Credential]? = nil,
        password: String? = nil,
        passwordRevisionDate: Date? = nil,
        totp: String? = nil,
        uris: [CipherLoginUriModel]? = nil,
        username: String? = nil
    ) -> CipherLoginModel {
        self.init(
            autofillOnPageLoad: autofillOnPageLoad,
            fido2Credentials: fido2Credentials,
            password: password,
            passwordRevisionDate: passwordRevisionDate,
            totp: totp,
            uris: uris,
            username: username
        )
    }
}
