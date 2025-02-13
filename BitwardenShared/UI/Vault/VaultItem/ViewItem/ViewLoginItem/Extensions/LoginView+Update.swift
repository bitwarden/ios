import BitwardenSdk // swiftlint:disable:this file_name

// MARK: - LoginView+Update

extension BitwardenSdk.LoginView {
    /// initializes a new LoginView with updated properties
    ///
    /// - Parameters:
    ///   - loginView: A `BitwardenSdk.LoginView` to use as a base for the update.
    ///   - loginState: The `LoginItemState` used to create or update the login view.
    ///
    init(loginView: BitwardenSdk.LoginView?, loginState: LoginItemState) {
        self.init(
            username: loginState.username.nilIfEmpty,
            password: loginState.password.nilIfEmpty,
            passwordRevisionDate: loginState.passwordUpdatedDate ?? loginView?.passwordRevisionDate,
            uris: loginState.uris.compactMap(\.loginUriView).nilIfEmpty,
            totp: loginState.authenticatorKey.nilIfEmpty,
            autofillOnPageLoad: loginView?.autofillOnPageLoad,
            fido2Credentials: loginState.fido2Credentials.nilIfEmpty
        )
    }
}
