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

    /// Whether the password type should be enforced or not
    var overridePasswordType: Bool?
}

extension PasswordGenerationOptions {
    /// Sets the password's minimum length.
    ///
    /// - Parameter minimumLength: The password's minimum length.
    ///
    mutating func setMinLength(_ minimumLength: Int) {
        length = max(length ?? minimumLength, minimumLength)
    }

    /// Sets the password's minimum number of lowercase characters.
    ///
    /// - Parameter minimum: The password's minimum number of lowercase characters.
    ///
    mutating func setMinLowercase(_ minimum: Int) {
        minLowercase = max(minLowercase ?? minimum, minimum)
    }


    /// Sets the password's minimum number of numbers.
    ///
    /// - Parameter minimumNumbers: The password's minimum number of numbers.
    ///
    mutating func setMinNumbers(_ minimumNumbers: Int) {
        minNumber = max(minNumber ?? minimumNumbers, minimumNumbers)
    }

    /// Sets the password's minimum number of words.
    ///
    /// - Parameter minimumNumberWords: The password's minimum number of words.
    ///
    mutating func setMinNumberWords(_ minimumNumberWords: Int) {
        numWords = max(numWords ?? minimumNumberWords, minimumNumberWords)
    }

    /// Sets the password's minimum number of special characters.
    ///
    /// - Parameter minimumSpecial: The password's minimum number of special characters.
    ///
    mutating func setMinSpecial(_ minimumSpecial: Int) {
        minSpecial = max(minSpecial ?? minimumSpecial, minimumSpecial)
    }

    /// Sets the password's minimum number of uppercase characters.
    ///
    /// - Parameter minimum: The password's minimum number of uppercase characters.
    ///
    mutating func setMinUppercase(_ minimum: Int) {
        minUppercase = max(minUppercase ?? minimum, minimum)
    }

    // MARK: Merge

    /// Merges `request` into these options taking the most restrictive values.
    ///
    /// Boolean flags are set to `true` if either source requires it. Length and minimum-count
    /// fields are raised to the maximum of the two values.
    ///
    /// - Parameter request: A `PasswordGeneratorRequest` whose constraints are merged in.
    ///
    mutating func apply(_ request: PasswordGeneratorRequest) {
        lowercase = lowercase == true || request.lowercase
        uppercase = uppercase == true || request.uppercase
        number = number == true || request.numbers
        special = special == true || request.special

        allowAmbiguousChar = (allowAmbiguousChar ?? true) && !request.avoidAmbiguous

        setMinLength(Int(request.length))

        if let min = request.minLowercase { setMinLowercase(Int(min)) }
        if let min = request.minUppercase { setMinUppercase(Int(min)) }
        if let min = request.minNumber { setMinNumbers(Int(min)) }
        if let min = request.minSpecial { setMinSpecial(Int(min)) }
    }
}
