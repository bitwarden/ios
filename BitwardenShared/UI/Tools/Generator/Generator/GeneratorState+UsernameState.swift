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

        /// The service used to generate a forwarded email alias.
        ///
        enum ForwardedEmailService: CaseIterable, Equatable, Menuable { // swiftlint:disable:this nesting
            /// Generate a forwarded email using addy.io.
            case addyIO

            /// Generate a forwarded email using DuckDuckGo.
            case duckDuckGo

            /// Generate a forwarded email using Fastmail.
            case fastmail

            /// Generate a forwarded email using Firefox Relay.
            case firefoxRelay

            /// Generate a forwarded email using SimpleLogin.
            case simpleLogin

            var localizedName: String {
                switch self {
                case .addyIO:
                    return Localizations.addyIo
                case .duckDuckGo:
                    return Localizations.duckDuckGo
                case .fastmail:
                    return Localizations.fastmail
                case .firefoxRelay:
                    return Localizations.firefoxRelay
                case .simpleLogin:
                    return Localizations.simpleLogin
                }
            }
        }

        // MARK: Properties

        /// The type of username to generate.
        var usernameGeneratorType = UsernameGeneratorType.plusAddressedEmail

        // MARK: Catch All Email Properties

        /// The user's domain for generating catch all emails.
        var domain: String = ""

        // MARK: Forwarded Email Properties

        /// The addy.io API access token to generate a forwarded email alias.
        var addyIOAPIAccessToken: String = ""

        /// The domain name used to generate a forwarded email alias with addy.io.
        var addyIODomainName: String = ""

        /// The DuckDuckGo API key used to generate a forwarded email alias.
        var duckDuckGoAPIKey: String = ""

        /// The Fastmail API Key used to generate a forwarded email alias
        var fastmailAPIKey: String = ""

        /// The Firefox Relay API access token used to generate a forwarded email alias
        var firefoxRelayAPIAccessToken: String = ""

        /// The service used to generate a forwarded email alias.
        var forwardedEmailService = ForwardedEmailService.addyIO

        /// Whether the service's API key is visible or not.
        var isAPIKeyVisible = false

        /// The simple login API key used to generate a forwarded email alias
        var simpleLoginAPIKey: String = ""

        // MARK: Plus Addressed Email Properties

        /// The user's email for generating plus addressed emails.
        var email: String = ""

        // MARK: Random Word Properties

        /// Whether to capitalize the random word.
        var capitalize: Bool = false

        /// Whether the random word should include numbers.
        var includeNumber: Bool = false
    }
}
