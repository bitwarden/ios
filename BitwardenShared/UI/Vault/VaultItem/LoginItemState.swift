import BitwardenSdk
import Foundation

// MARK: - LoginItemState

/// The state for adding a login item.
struct LoginItemState: Equatable {
    // MARK: Properties

    /// A flag indicating if the password field is visible.
    var isPasswordVisible: Bool = false

    /// The password for this item.
    var password: String = ""

    /// The date the password was last updated.
    var passwordUpdatedDate: Date?

    /// The uris associated with this item. Used with autofill.
    var uris: [UriState] = [UriState()]

    /// The username for this item.
    var username: String = ""

    /// BitwardenSDK loginView representation of loginItemState.
    var loginView: BitwardenSdk.LoginView {
        BitwardenSdk.LoginView(
            username: username.nilIfEmpty,
            password: password.nilIfEmpty,
            passwordRevisionDate: passwordUpdatedDate,
            uris: nil,
            totp: nil,
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
