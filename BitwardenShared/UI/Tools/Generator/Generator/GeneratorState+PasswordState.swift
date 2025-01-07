import BitwardenSdk

extension GeneratorState {
    /// Data model for the values that can be set for generating a password.
    ///
    struct PasswordState: Equatable {
        // MARK: Password Properties

        /// Whether the generated password should avoid ambiguous characters.
        var avoidAmbiguous: Bool = false

        /// Whether the generated password should contain lowercase characters.
        var containsLowercase: Bool = true

        /// Whether the generated password should contain numbers.
        var containsNumbers: Bool = true

        /// Whether the generated password should contain special characters.
        var containsSpecial: Bool = false

        /// Whether the generated password should contain uppercase characters.
        var containsUppercase: Bool = true

        /// The length of the generated password.
        var length: Int = 14

        /// A proxy value for getting and setting `length` as a double value (which is needed for
        /// displaying the slider).
        var lengthDouble: Double {
            get { Double(length) }
            set { length = Int(newValue) }
        }

        /// The calculated minimum length the password can be based on constraints.
        var minimumLength: Int {
            let minimumLowercase = containsLowercase ? 1 : 0
            let minimumUppercase = containsUppercase ? 1 : 0
            let minimumNumber = containsNumbers ? max(1, minimumNumber) : 0
            let minimumSpecial = containsSpecial ? max(1, minimumSpecial) : 0
            return minimumLowercase + minimumUppercase + minimumNumber + minimumSpecial
        }

        /// The minimum number of numbers in the generated password.
        var minimumNumber: Int = 1

        /// The minimum number of special characters in the generated password.
        var minimumSpecial: Int = 1

        // MARK: Passphrase Properties

        /// Whether to capitalize the passphrase words.
        var capitalize: Bool = false

        /// Whether the passphrase should include numbers.
        var includeNumber: Bool = false

        /// The number of words to include in the passphrase.
        var numberOfWords: Int = 3

        /// The separator to put between words in the passphrase.
        var wordSeparator: String = "-"

        // MARK: Methods

        /// Updates the state based on the user's persisted password generation options.
        ///
        /// - Parameter options: The user's saved options.
        ///
        mutating func update(with options: PasswordGenerationOptions) {
            // Password Properties
            avoidAmbiguous = !(options.allowAmbiguousChar ?? !avoidAmbiguous)
            containsLowercase = options.lowercase ?? containsLowercase
            containsNumbers = options.number ?? containsNumbers
            containsSpecial = options.special ?? containsSpecial
            containsUppercase = options.uppercase ?? containsUppercase
            length = options.length ?? length
            minimumNumber = options.minNumber ?? minimumNumber
            minimumSpecial = options.minSpecial ?? minimumSpecial

            // Passphrase Properties
            capitalize = options.capitalize ?? capitalize
            includeNumber = options.includeNumber ?? includeNumber
            numberOfWords = options.numWords ?? numberOfWords
            wordSeparator = options.wordSeparator ?? wordSeparator
        }

        /// Validates and updates the password generation options to ensure no invalid combinations.
        ///
        mutating func validateOptions() {
            if !containsLowercase, !containsNumbers, !containsSpecial, !containsUppercase {
                containsLowercase = true
            }

            if length < minimumLength {
                length = minimumLength
            }
        }
    }
}

extension GeneratorState.PasswordState {
    /// Returns a `PassphraseGeneratorRequest` containing the user selected settings for generating
    /// a passphrase.
    var passphraseGeneratorRequest: PassphraseGeneratorRequest {
        PassphraseGeneratorRequest(
            numWords: UInt8(numberOfWords),
            wordSeparator: wordSeparator,
            capitalize: capitalize,
            includeNumber: includeNumber
        )
    }

    /// Returns a `PasswordGeneratorRequest` containing the user selected settings for generating a
    /// password.
    var passwordGeneratorRequest: PasswordGeneratorRequest {
        PasswordGeneratorRequest(
            lowercase: containsLowercase,
            uppercase: containsUppercase,
            numbers: containsNumbers,
            special: containsSpecial,
            length: UInt8(length),
            avoidAmbiguous: avoidAmbiguous,
            minLowercase: containsLowercase ? 1 : nil,
            minUppercase: containsUppercase ? 1 : nil,
            minNumber: containsNumbers ? UInt8(minimumNumber) : nil,
            minSpecial: containsSpecial ? UInt8(minimumSpecial) : nil
        )
    }

    /// Returns a `PasswordGenerationOptions` containing the user selected settings for generating
    /// a password used to persist the options between app launches.
    func passwordGenerationOptions(generatorType: GeneratorType) -> PasswordGenerationOptions {
        let type: PasswordGeneratorType = switch generatorType {
        case .passphrase: .passphrase
        case .password: .password
        default: .password
        }
        return PasswordGenerationOptions(
            allowAmbiguousChar: !avoidAmbiguous,
            capitalize: capitalize,
            includeNumber: includeNumber,
            length: length,
            lowercase: containsLowercase,
            minLowercase: nil,
            minNumber: minimumNumber,
            minSpecial: minimumSpecial,
            minUppercase: nil,
            number: containsNumbers,
            numWords: numberOfWords,
            special: containsSpecial,
            type: type,
            uppercase: containsUppercase,
            wordSeparator: wordSeparator
        )
    }
}
