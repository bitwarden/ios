extension GeneratorState {
    /// Data model for the values that can be set for generating a username.
    ///
    struct UsernameState: Equatable {
        // MARK: Types

        /// The type of username to generate.
        ///
        enum UsernameGeneratorType: CaseIterable, Equatable, Menuable { // swiftlint:disable:this nesting
            /// Generate a catch all email.
            case catchAllEmail

            /// Generate a forwarded email.
            case forwardedEmail

            /// Generate a plus addressed email.
            case plusAddressedEmail

            /// Generate a random word.
            case randomWord

            /// All of the cases to show in the menu.
            static let allCases: [Self] = [.plusAddressedEmail, .catchAllEmail, .forwardedEmail, .randomWord]

            var localizedName: String {
                switch self {
                case .catchAllEmail:
                    return Localizations.catchAllEmail
                case .forwardedEmail:
                    return Localizations.forwardedEmailAlias
                case .plusAddressedEmail:
                    return Localizations.plusAddressedEmail
                case .randomWord:
                    return Localizations.randomWord
                }
            }

            /// A localized description of the field, used as the footer text below the menu value in the UI.
            var localizedDescription: String? {
                switch self {
                case .catchAllEmail:
                    return Localizations.catchAllEmailDescription
                case .forwardedEmail:
                    return Localizations.forwardedEmailDescription
                case .plusAddressedEmail:
                    return Localizations.plusAddressedEmailDescription
                case .randomWord:
                    return nil
                }
            }
        }

        // MARK: Properties

        /// The type of username to generate.
        var usernameGeneratorType = UsernameGeneratorType.plusAddressedEmail

        // MARK: Plus Addressed Email Properties

        /// The user's email for generating plus addressed emails.
        var email: String = ""

        // MARK: Catch All Email Properties

        /// The user's domain for generating catch all emails.
        var domain: String = ""

        // MARK: Random Word Properties

        /// Whether to capitalize the random word.
        var capitalize: Bool = false

        /// Whether the random word should include numbers.
        var includeNumber: Bool = false
    }
}
