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
        var existingItem: AuthenticatorItemView? {
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
    var digits: Int

    /// The id of the item
    var id: String

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
        accountName: String,
        algorithm: TOTPCryptoHashAlgorithm,
        configuration: Configuration,
        digits: Int,
        id: String,
        isAdvancedExpanded: Bool = false,
        issuer: String,
        name: String,
        period: TotpPeriodOptions,
        secret: String,
        totpState: LoginTOTPState
    ) {
        self.accountName = accountName
        self.algorithm = algorithm
        self.configuration = configuration
        self.digits = digits
        self.id = id
        self.isAdvancedExpanded = isAdvancedExpanded
        self.issuer = issuer
        self.name = name
        self.period = period
        self.secret = secret
        self.totpState = totpState
    }

    init?(existing authenticatorItemView: AuthenticatorItemView) {
        guard let keyModel = TOTPKeyModel(authenticatorKey: authenticatorItemView.totpKey) else {
            return nil
        }
        self.init(
            accountName: keyModel.accountName ?? "",
            algorithm: keyModel.algorithm,
            configuration: .existing(authenticatorItemView: authenticatorItemView),
            digits: keyModel.digits,
            id: authenticatorItemView.id,
            issuer: keyModel.issuer ?? "",
            name: keyModel.issuer ?? authenticatorItemView.name,
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
            name: issuer,
            totpKey: totpState.rawAuthenticatorKeyString
        )
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
