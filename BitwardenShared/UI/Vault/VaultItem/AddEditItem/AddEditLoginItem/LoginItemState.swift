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

    var time: TOTPTime {
        totpState?.totpTime
            ?? .currentTime
    }

    var totpCode: TOTPCodeModel? {
        totpState?.codeModel
    }

    var totpKey: TOTPKeyModel? {
        totpState?.authKeyModel
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

/// A model defining the state of a TOTP key/code pair along with a TimeProvider to calculate expiration.
///
struct LoginTOTPState: Equatable {
    /// The auth key model used to generate TOTP codes.
    ///
    let authKeyModel: TOTPKeyModel

    /// The current TOTP code for the Login Item.
    ///
    var codeModel: TOTPCodeModel?

    /// The model used to provide time for a TOTP code expiration check.
    ///
    let totpTime: TOTPTime

    /// Initializes a LoginTOTPState model.
    ///
    /// - Parameters:
    ///   - authKeyModel: The TOTP key model.
    ///   - codeModel: The TOTP code model. Defaults to `nil`.
    ///   - totpTime: The TimeProvider used to calculate code expiration.
    ///
    init(
        authKeyModel: TOTPKeyModel,
        codeModel: TOTPCodeModel? = nil,
        totpTime: TOTPTime
    ) {
        self.authKeyModel = authKeyModel
        self.codeModel = codeModel
        self.totpTime = totpTime
    }

    /// Optionally Initializes a LoginTOTPState model without a current code.
    ///
    /// - Parameters:
    ///   - authKeyModel: The optional TOTP key model.
    ///   - totpTime: The TimeProvider used to calculate code expiration.
    ///
    init?(_ authKeyModel: TOTPKeyModel?, time: TOTPTime) {
        guard let authKeyModel else { return nil }
        self.authKeyModel = authKeyModel
        codeModel = nil
        totpTime = time
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

    /// A model to provide reference times for TOTP code exipration
    var time: TOTPTime { get }

    /// The TOTP code model
    var totpCode: TOTPCodeModel? { get }

    /// The uris associated with this item. Used with autofill.
    var uris: [UriState] { get }

    /// The username for this item.
    var username: String { get }
}

extension LoginItemState: ViewLoginItemState {}
