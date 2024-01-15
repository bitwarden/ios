import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension LoginItemState {
    static func fixture(
        canViewPassword: Bool = true,
        isPasswordVisible: Bool = false,
        isTOTPAvailable: Bool = true,
        password: String = "",
        totpState: LoginTOTPState = .none,
        uris: [UriState] = [],
        username: String = ""
    ) -> Self {
        LoginItemState(
            canViewPassword: canViewPassword,
            isPasswordVisible: isPasswordVisible,
            isTOTPAvailable: isTOTPAvailable,
            password: password,
            totpState: totpState,
            uris: uris,
            username: username
        )
    }
}
