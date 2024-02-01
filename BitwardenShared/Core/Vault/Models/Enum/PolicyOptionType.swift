/// An enumeration of policy options.
///
enum PolicyOptionType: String {
    // MARK: Password Generation Options

    case action

    /// A policy option for whether to capitalize the passphrase words.
    case capitalize

    /// A policy option for the default type of the password generator.
    case defaultType

    /// A policy option for whether to include a number in a passphrase.
    case includeNumber

    case minutes

    /// A policy option for the minimum length.
    case minLength

    /// A policy option for the minimum number of numbers.
    case minNumbers

    /// A policy option for the minimum number of words.
    case minNumberWords

    /// A policy option for the minimum number of special characters.
    case minSpecial

    /// A policy option for whether to include lowercase characters.
    case useLower

    /// A policy option for whether to include numbers.
    case useNumbers

    /// A policy option for whether to include special characters.
    case useSpecial

    /// A policy option for whether to include uppercase characters.
    case useUpper

    // MARK: Send Options

    /// A policy option for whether the send should disable the hide email option.
    case disableHideEmail
}
