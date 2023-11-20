/// A data model containing the options used to generate a password, which is persisted between app
/// launches to maintain the user's selected options.
///
struct PasswordGenerationOptions: Codable, Equatable {
    // MARK: Properties

    /// Whether the generated password allows ambiguous characters.
    var allowAmbiguousChar: Bool?

    /// Whether to capitalize the passphrase words.
    var capitalize: Bool?

    /// Whether the passphrase should include numbers.
    var includeNumber: Bool?

    /// The length of the generated password.
    var length: Int?

    /// Whether the generated password should contain lowercase characters.
    var lowercase: Bool?

    /// The minimum number of lowercase letters in the generated password.
    var minLowercase: Int?

    /// The minimum number of numbers in the generated password.
    var minNumber: Int?

    /// The minimum number of special characters in the generated password.
    var minSpecial: Int?

    /// The minimum number of uppercase letters in the generated password.
    var minUppercase: Int?

    /// Whether the generated password should contain numbers.
    var number: Bool?

    /// The number of words to include in the passphrase.
    var numWords: Int?

    /// Whether the generated password should contain special characters.
    var special: Bool?

    /// The type of password to generate.
    var type: PasswordGeneratorType?

    /// Whether the generated password should contain uppercase characters.
    var uppercase: Bool?

    /// The separator to put between words in the passphrase.
    var wordSeparator: String?
}
