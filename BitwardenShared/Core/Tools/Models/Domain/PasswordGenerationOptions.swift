import BitwardenSdk

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
    // MARK: Computed Requests

    /// Converts these options to a `PassphraseGeneratorRequest` using sensible defaults.
    var passphraseGeneratorRequest: PassphraseGeneratorRequest {
        PassphraseGeneratorRequest(
            numWords: UInt8(clamping: numWords ?? 3),
            wordSeparator: wordSeparator ?? "-",
            capitalize: capitalize ?? false,
            includeNumber: includeNumber ?? false,
        )
    }

    /// Converts these options to a `PasswordGeneratorRequest` using sensible defaults.
    var passwordGeneratorRequest: PasswordGeneratorRequest {
        let hasLower = lowercase ?? true
        let hasUpper = uppercase ?? true
        let hasNumbers = number ?? true
        let hasSpecial = special ?? false

        return PasswordGeneratorRequest(
            lowercase: hasLower,
            uppercase: hasUpper,
            numbers: hasNumbers,
            special: hasSpecial,
            length: UInt8(clamping: length ?? 14),
            avoidAmbiguous: !(allowAmbiguousChar ?? true),
            minLowercase: hasLower ? UInt8(clamping: minLowercase ?? 1) : nil,
            minUppercase: hasUpper ? UInt8(clamping: minUppercase ?? 1) : nil,
            minNumber: hasNumbers ? UInt8(clamping: minNumber ?? 1) : nil,
            minSpecial: hasSpecial ? UInt8(clamping: minSpecial ?? 1) : nil,
        )
    }

    // MARK: Methods

    /// Sets the password's minimum length.
    ///
    /// - Parameter minimumLength: The password's minimum length.
    ///
    mutating func setMinLength(_ minimumLength: Int) {
        if let length {
            if length > minimumLength {
                self.length = minimumLength
            }
        } else {
            length = minimumLength
        }
    }

    /// Sets the password's minimum number of lowercase characters.
    ///
    /// - Parameter minimum: The password's minimum number of lowercase characters.
    ///
    mutating func setMinLowercase(_ minimum: Int) {
        if let minLowercase, minLowercase >= minimum { return }
        minLowercase = minimum
    }

    /// Sets the password's minimum number of numbers.
    ///
    /// - Parameter minimumNumbers: The password's minimum number of numbers.
    ///
    mutating func setMinNumbers(_ minimumNumbers: Int) {
        if let minNumber, minNumber < minimumNumbers {
            self.minNumber = minimumNumbers
        } else if minNumber == nil {
            minNumber = minimumNumbers
        }
    }

    /// Sets the password's minimum number of words.
    ///
    /// - Parameter minimumNumberWords: The password's minimum number of words.
    ///
    mutating func setMinNumberWords(_ minimumNumberWords: Int) {
        if let numWords, numWords < minimumNumberWords {
            self.numWords = minimumNumberWords
        } else if numWords == nil {
            numWords = minimumNumberWords
        }
    }

    /// Sets the password's minimum number of special characters.
    ///
    /// - Parameter minimumLength: The password's minimum number of special characters.
    ///
    mutating func setMinSpecial(_ minimumSpecial: Int) {
        if let minSpecial, minSpecial < minimumSpecial {
            self.minSpecial = minimumSpecial
        } else if minSpecial == nil {
            minSpecial = minimumSpecial
        }
    }

    /// Sets the password's minimum number of uppercase characters.
    ///
    /// - Parameter minimum: The password's minimum number of uppercase characters.
    ///
    mutating func setMinUppercase(_ minimum: Int) {
        if let minUppercase, minUppercase >= minimum { return }
        minUppercase = minimum
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
