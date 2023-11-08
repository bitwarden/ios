import BitwardenSdk

extension GeneratorState {
    /// Data model for the values that can be set for generating a password.
    ///
    struct PasswordState: Equatable {
        // MARK: Types

        /// The type of password to generate.
        ///
        enum PasswordGeneratorType: CaseIterable, Equatable, Menuable { // swiftlint:disable:this nesting
            /// Generate a passphrase.
            case passphrase

            /// Generate a password.
            case password

            /// All of the cases to show in the menu.
            static let allCases: [Self] = [.password, .passphrase]

            var localizedName: String {
                switch self {
                case .password:
                    return Localizations.password
                case .passphrase:
                    return Localizations.passphrase
                }
            }
        }

        // MARK: Properties

        /// The type of password to generate.
        var passwordGeneratorType = PasswordGeneratorType.password

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

        /// The minimum number of numbers in the generated password.
        var minimumNumber: Int = 1

        /// The minimum number of special characters in the generated password.
        var minimumSpecial: Int = 1

        // MARK: Passphrase Properties

        /// Whether the capitalize the passphrase words.
        var capitalize: Bool = false

        /// Whether the passphrase should include numbers.
        var includeNumber: Bool = false

        /// The number of words to include in the passphrase.
        var numberOfWords: Int = 3

        /// The separator to put between words in the passphrase.
        var wordSeparator: String = "-"
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
            minLowercase: nil,
            minUppercase: nil,
            minNumber: nil, // TODO: BIT-980 Fix type mismatch with SDK (SDK expects bool not int).
            minSpecial: nil // TODO: BIT-980 Fix type mismatch with SDK (SDK expects bool not int).
        )
    }
}
