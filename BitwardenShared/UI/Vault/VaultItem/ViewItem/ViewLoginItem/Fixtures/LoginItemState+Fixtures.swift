import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension LoginItemState {
    static func fixture(
        canViewPassword: Bool = true,
        isPasswordVisible: Bool = false,
        password: String = "",
        uris: [UriState] = [],
        username: String = ""
    ) -> Self {
        LoginItemState(
            canViewPassword: canViewPassword,
            isPasswordVisible: isPasswordVisible,
            password: password,
            uris: uris,
            username: username
        )
    }
}
