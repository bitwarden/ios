import BitwardenSdk

/// Synchronous actions that can be processed by an `EditItemProcessor`.
enum EditAuthenticatorItemAction: Equatable {
    /// The account name field was changed.
    case accountNameChanged(String)

    /// The advanced button was pressed.
    case advancedPressed

    /// The algorithm field was changed.
    case algorithmChanged(TOTPCryptoHashAlgorithm)

    /// The digits field was changed.
    case digitsChanged(Int)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The issuer field was changed
    case issuerChanged(String)

    /// The item's name was changed
    case nameChanged(String)

    /// The item's period was changed
    case periodChanged(TotpPeriodOptions)

    /// The secret field was changed.
    case secretChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The toggle secret visibility button was changed.
    case toggleSecretVisibilityChanged(Bool)

    /// The OTP type was changed.
    case totpTypeChanged(TotpTypeOptions)
}
