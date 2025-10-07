// swiftlint:disable:this file_name

import BitwardenSdk

extension BitwardenSdk.LoginListView {
    static func fixture(
        fido2Credentials: [Fido2CredentialListView]? = nil,
        hasFido2: Bool = false,
        username: String? = nil,
        totp: EncString? = nil,
        uris: [LoginUriView]? = nil,
    ) -> LoginListView {
        .init(
            fido2Credentials: fido2Credentials,
            hasFido2: hasFido2,
            username: username,
            totp: totp,
            uris: uris,
        )
    }
}
