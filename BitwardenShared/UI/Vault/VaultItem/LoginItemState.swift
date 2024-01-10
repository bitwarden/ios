import BitwardenSdk
import Foundation

// MARK: - LoginItemState

/// The state for adding a login item.
struct LoginItemState: Equatable {
    // MARK: Properties

    /// Whether the user has permissions to view the cipher's password.
    var canViewPassword: Bool = true

    /// A flag indicating if the password field is visible.
    var isPasswordVisible: Bool = false

    /// A flag indicating if the totp feature is available.
    let isTOTPAvailable: Bool

    /// The password for this item.
    var password: String = ""

    /// The date the password was last updated.
    var passwordUpdatedDate: Date?

    /// The TOTP key/code state.
    var totpState: LoginTOTPState?

    /// The uris associated with this item. Used with autofill.
    var uris: [UriState] = [UriState()]

    /// The username for this item.
    var username: String = ""

    /// The TOTP Key.
    var authenticatorKey: String? {
        totpState?.authKeyModel.rawAuthenticatorKey
    }

    /// BitwardenSDK loginView representation of loginItemState.
    var loginView: BitwardenSdk.LoginView {
        BitwardenSdk.LoginView(
            username: username.nilIfEmpty,
            password: password.nilIfEmpty,
            passwordRevisionDate: passwordUpdatedDate,
            uris: nil,
            totp: authenticatorKey,
            autofillOnPageLoad: nil
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
    var time: TOTPTime {
        totpState?.totpTime
            ?? .currentTime
    }

    var totpCode: TOTPCodeModel? {
        totpState?.codeModel
    }
}
