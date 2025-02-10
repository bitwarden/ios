import BitwardenSdk
import Foundation

// MARK: - LoginItemState

/// The state for adding a login item.
struct LoginItemState: Equatable {
    // MARK: Properties

    /// Whether the user has permissions to view the cipher's password.
    var canViewPassword: Bool = true

    /// Whether the user has permissions to edit the cipher
    var editView: Bool = true

    /// The FIDO2 credentials for the login.
    var fido2Credentials: [Fido2Credential] = []

    /// Whether the auth key is visible.
    var isAuthKeyVisible: Bool = false

    /// A flag indicating if the password field is visible.
    var isPasswordVisible: Bool = false

    /// A flag indicating if the totp feature is available.
    let isTOTPAvailable: Bool

    /// Whether the user can see the TOTP code.
    var isTOTPCodeVisible: Bool = false

    /// The password for this item.
    var password: String = ""

    /// The password history count, if it exists.
    var passwordHistoryCount: Int?

    /// The date the password was last updated.
    var passwordUpdatedDate: Date?

    /// A toast message to show in the view.
    var toast: Toast?

    /// The TOTP key/code state.
    var totpState: LoginTOTPState

    /// The uris associated with this item. Used with autofill.
    var uris: [UriState] = [UriState()]

    /// The username for this item.
    var username: String = ""

    /// The TOTP Key.
    var authenticatorKey: String {
        totpState.rawAuthenticatorKeyString ?? ""
    }

    /// BitwardenSDK loginView representation of loginItemState.
    var loginView: BitwardenSdk.LoginView {
        BitwardenSdk.LoginView(
            username: username.nilIfEmpty,
            password: password.nilIfEmpty,
            passwordRevisionDate: passwordUpdatedDate,
            uris: uris.compactMap(\.loginUriView).nilIfEmpty,
            totp: authenticatorKey.nilIfEmpty,
            autofillOnPageLoad: nil,
            fido2Credentials: nil
        )
    }
}

extension LoginItemState {
    /// The website host that's passed to the generator to generate a website username.
    var generatorEmailWebsite: String? {
        uris.first.flatMap { URL(string: $0.uri)?.sanitized.host }
    }
}

extension LoginItemState: ViewLoginItemState {
    var totpCode: TOTPCodeModel? {
        totpState.codeModel
    }
}
