import BitwardenSdk // swiftlint:disable:this file_name

// MARK: - LoginView+Update

extension BitwardenSdk.LoginView {
    /// initializes a new LoginView with updated properties
    ///
    /// - Parameters:
    ///   - loginView: A `BitwardenSdk.LoginView` to use as a base for the update.
    ///   - properties: The `CipherItemProperties` used to create or update the login view.
    ///
    init(loginView: BitwardenSdk.LoginView?, properties: CipherItemProperties) {
        self.init(
            username: properties.username.nilIfEmpty,
            password: properties.password.nilIfEmpty,
            passwordRevisionDate: loginView?.passwordRevisionDate,
            uris: loginView?.uris,
            totp: loginView?.totp,
            autofillOnPageLoad: loginView?.autofillOnPageLoad
        )
    }
}
