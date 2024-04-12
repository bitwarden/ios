import BitwardenSdk
import Foundation

// MARK: - AuthenticatorItemState

/// An object that defines the current state of any view interacting with an authenticator item.
///
struct AuthenticatorItemState: Equatable {
    // MARK: Types

    /// An enum defining if the state is a new or existing item.
    enum Configuration: Equatable {
        /// We are creating a new item.
        case add

        /// We are viewing or editing an existing item.
        case existing(authenticatorItemView: AuthenticatorItemView)

        /// The existing `AuthenticatorItemView` if the configuration is `existing`.
        var existingToken: AuthenticatorItemView? {
            guard case let .existing(authenticatorItemView) = self else { return nil }
            return authenticatorItemView
        }
    }

    // MARK: Properties

    /// The account name of the item
    var accountName: String

    /// The algorithm of the item
    var algorithm: TOTPCryptoHashAlgorithm

    /// The Add or Existing Configuration.
    let configuration: Configuration

    /// The number of digits in the OTP
    var digits: TotpDigitsOptions

    /// A flag indicating if the advanced section is expanded.
    var isAdvancedExpanded: Bool = false

    /// A flag indicating if the secret field is visible
    var isSecretVisible: Bool = false

    /// The issuer of the item
    var issuer: String

    /// The name of this item.
    var name: String

    /// The period for the OTP
    var period: TotpPeriodOptions

    /// The secret of the OTP
    var secret: String

    /// A toast for views
    var toast: Toast?

    /// The TOTP key/code state.
    var totpState: LoginTOTPState

    // MARK: Initialization

    init(
        configuration: Configuration,
        name: String,
        accountName: String,
        algorithm: TOTPCryptoHashAlgorithm,
        digits: TotpDigitsOptions,
        issuer: String,
        period: TotpPeriodOptions,
        secret: String,
        totpState: LoginTOTPState
    ) {
        self.configuration = configuration
        self.name = name
        self.totpState = totpState
        self.accountName = accountName
        self.algorithm = algorithm
        self.issuer = issuer
        self.digits = digits
        self.period = period
        self.secret = secret
    }

    init?(existing authenticatorItemView: AuthenticatorItemView) {
        guard let keyModel = TOTPKeyModel(authenticatorKey: authenticatorItemView.totpKey) else {
            return nil
        }
        self.init(
            configuration: .existing(authenticatorItemView: authenticatorItemView),
            name: authenticatorItemView.name,
            accountName: keyModel.accountName ?? "",
            algorithm: keyModel.algorithm,
            digits: TotpDigitsOptions(rawValue: keyModel.digits) ?? .six,
            issuer: keyModel.issuer ?? "",
            period: TotpPeriodOptions(rawValue: keyModel.period) ?? .thirty,
            secret: keyModel.base32Key,
            totpState: LoginTOTPState(authenticatorItemView.totpKey)
        )
    }
}

extension AuthenticatorItemState: EditAuthenticatorItemState {
    var editState: EditAuthenticatorItemState {
        self
    }
}

extension AuthenticatorItemState {
    /// Returns an `AuthenticatorItemView` based on the
    /// properties of the `AuthenticatorItemState`.
    ///
    func newAuthenticatorItemView() -> AuthenticatorItemView {
        AuthenticatorItemView(
            id: UUID().uuidString,
            name: name,
            totpKey: totpState.rawAuthenticatorKeyString
        )
    }
}

enum TotpDigitsOptions: Int, Menuable, CaseIterable {
    case six = 6
    case eight = 8
    case ten = 10
    case twelve = 12

    var localizedName: String {
        "\(rawValue)"
    }
}

enum TotpPeriodOptions: Int, Menuable, CaseIterable {
    case thirty = 30
    case sixty = 60
    case ninety = 90

    var localizedName: String {
        switch self {
        case .thirty:
            Localizations.thirtySeconds
        case .sixty:
            Localizations.sixtySeconds
        case .ninety:
            Localizations.ninetySeconds
        }
    }
}

