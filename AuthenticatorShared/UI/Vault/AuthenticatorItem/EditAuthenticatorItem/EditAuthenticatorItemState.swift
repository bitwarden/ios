import BitwardenSdk
import Foundation

// MARK: - EditAuthenticatorItemState

/// The state of an `EditAuthenticatorItemView`
/// and `EditAdvancedAuthenticatorItemView`
protocol EditAuthenticatorItemState: Sendable {
    // MARK: Properties

    /// The account of the item
    var accountName: String { get set }

    /// The algorithm of the OTP item
    var algorithm: TOTPCryptoHashAlgorithm { get set }

    /// The Add or Existing Configuration.
    var configuration: AuthenticatorItemState.Configuration { get }

    /// The number of digits in the OTP
    var digits: Int { get set }

    /// The ID of the item
    var id: String { get }

    /// A flag indicating if the advanced section is expanded.
    var isAdvancedExpanded: Bool { get set }

    /// A flag indicating if this item is favorited.
    var isFavorited: Bool { get set }

    /// A flag indicating if the secret is visible.
    var isSecretVisible: Bool { get set }

    /// The issuer of the item
    var issuer: String { get set }

    /// The name of this item.
    var name: String { get set }

    /// The secret of the OTP item
    var secret: String { get set }

    /// The period of the OTP in seconds
    var period: TotpPeriodOptions { get set }

    /// A toast for views
    var toast: Toast? { get set }

    /// The TOTP key/code state.
    var totpState: LoginTOTPState { get set }

    /// The currently selected TOTP type.
    var totpType: TotpTypeOptions { get set }
}
