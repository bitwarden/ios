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

    /// The password for this item.
    var password: String = ""

    /// The date the password was last updated.
    var passwordUpdatedDate: Date?

    /// The TOTP key configuration
    var totpKey: TOTPCodeConfig?

    /// The uris associated with this item. Used with autofill.
    var uris: [UriState] = [UriState()]

    /// The username for this item.
    var username: String = ""

    /// The TOTP Key.
    var authenticatorKey: String? {
        totpKey?.authenticatorKey
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

// MARK: ViewLoginItemState

protocol ViewLoginItemState: Sendable {
    // MARK: Properties

    /// The TOTP Key.
    var authenticatorKey: String? { get }

    /// Whether the user has permissions to view the cipher's password.
    var canViewPassword: Bool { get }

    /// A flag indicating if the TOTP feature is available.
    var isTOTPAvailable: Bool { get }

    /// A flag indicating if the password field is visible.
    var isPasswordVisible: Bool { get }

    /// The password for this item.
    var password: String { get }

    /// The date the password was last updated.
    var passwordUpdatedDate: Date? { get }

    /// The TOTP key configuration
    var totpKey: TOTPCodeConfig? { get }

    /// The uris associated with this item. Used with autofill.
    var uris: [UriState] { get }

    /// The username for this item.
    var username: String { get }
}

extension LoginItemState: ViewLoginItemState {}

// TODO: BIT-1262: Hide TOTP for non-Premium Accounts
extension ViewLoginItemState {
    var isTOTPAvailable: Bool {
        true
    }
}
