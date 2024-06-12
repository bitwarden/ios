import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension LoginItemState {
    static func fixture(
        canViewPassword: Bool = true,
        fido2Credentials: [Fido2Credential] = [],
        isPasswordVisible: Bool = false,
        isTOTPAvailable: Bool = true,
        password: String = "",
        totpState: LoginTOTPState = .none,
        uris: [UriState] = [],
        username: String = ""
    ) -> Self {
        LoginItemState(
            canViewPassword: canViewPassword,
            fido2Credentials: fido2Credentials,
            isPasswordVisible: isPasswordVisible,
            isTOTPAvailable: isTOTPAvailable,
            password: password,
            totpState: totpState,
            uris: uris,
            username: username
        )
    }
}
