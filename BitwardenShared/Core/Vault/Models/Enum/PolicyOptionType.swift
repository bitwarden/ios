/// An enumeration of policy options.
///
enum PolicyOptionType: String {
    // MARK: Organization User Notification Options

    /// A policy option for the dismiss button text of the notification banner.
    case buttonText

    /// A policy option for the body text of the notification banner.
    case description

    /// A policy option for the header text of the notification banner.
    case header

    /// A policy option for whether to show the notification banner after every login.
    case showAfterEveryLogin

    // MARK: Password Generation Options

    /// A policy option for the vault timeout action.
    case action

    /// A policy option for whether to capitalize the passphrase words.
    case capitalize

    /// A policy option for the enforced type of the password generator.
    case overridePasswordType

    /// A policy option for whether to include a number in a passphrase.
    case includeNumber

    /// A policy option for the vault timeout value in minutes.
    case minutes

    /// A policy option for the minimum length.
    case minLength

    /// A policy option for the minimum number of numbers.
    case minNumbers

    /// A policy option for the minimum number of words.
    case minNumberWords

    /// A policy option for the minimum number of special characters.
    case minSpecial

    /// A policy option for the vault timeout type.
    case type

    /// A policy option for whether to include lowercase characters.
    case useLower

    /// A policy option for whether to include numbers.
    case useNumbers

    /// A policy option for whether to include special characters.
    case useSpecial

    /// A policy option for whether to include uppercase characters.
    case useUpper

    // MARK: Master Password Policy Options

    /// A policy option for whether to enforce this policy on login.
    case enforceOnLogin

    /// A policy option for the minimum number of complexity.
    case minComplexity

    /// A policy option for whether to require lowercase characters.
    case requireLower

    /// A policy option for whether to require number characters.
    case requireNumbers

    /// A policy option for whether to require special characters.
    case requireSpecial

    /// A policy option for whether to require uppercase characters.
    case requireUpper

    // MARK: Send Controls Options

    /// A policy option for the domains that recipient emails must match when the enforced access
    /// control is email verification ("Specific people"). Encoded as a comma-separated string.
    case allowedDomains

    /// A policy option for the Send types users are allowed to create. Encoded as an array of
    /// `SendType` raw values (`0` = text, `1` = file); `[0, 1]` or a missing key means both types
    /// are allowed.
    case allowedSendTypes

    /// A policy option for the deletion date users are required to use on Sends, encoded as an
    /// `Int` number of hours from creation (e.g. `168` = 7 days). A missing key means the deletion
    /// date is not restricted.
    case deletionHours

    /// A policy option for whether the send should disable the hide email option.
    case disableHideEmail

    /// A policy option for whether the Send Controls policy disables creating and editing Sends.
    case disableSend

    /// A policy option for the access control (auth type) users are required to use on Sends.
    ///
    /// Encoded as an int matching the server's `WhoCanAccessType`: `0` = Any (unrestricted),
    /// `1` = PasswordProtected, `2` = SpecificPeople (email verification).
    case whoCanAccess
}
