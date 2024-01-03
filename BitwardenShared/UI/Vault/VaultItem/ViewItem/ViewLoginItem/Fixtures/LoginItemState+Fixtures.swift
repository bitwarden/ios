import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension LoginItemState {
    static func fixture(
        canViewPassword: Bool = true,
        isPasswordVisible: Bool = false,
        isTOTPAvailable: Bool = true,
        password: String = "",
        uris: [UriState] = [],
        username: String = ""
    ) -> Self {
        LoginItemState(
            canViewPassword: canViewPassword,
            isPasswordVisible: isPasswordVisible,
            isTOTPAvailable: isTOTPAvailable,
            password: password,
            uris: uris,
            username: username
        )
    }
}
