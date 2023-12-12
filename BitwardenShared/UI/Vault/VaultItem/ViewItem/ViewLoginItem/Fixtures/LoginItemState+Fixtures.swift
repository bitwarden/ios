import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension LoginItemState {
    static func fixture(
        isPasswordVisible: Bool = false,
        password: String = "",
        uris: [UriState] = [],
        username: String = ""
    ) -> Self {
        LoginItemState(
            isPasswordVisible: isPasswordVisible,
            password: password,
            uris: uris,
            username: username
        )
    }
}
