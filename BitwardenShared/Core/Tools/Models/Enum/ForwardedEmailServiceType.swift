import BitwardenResources

/// The service used to generate a forwarded email alias.
///
enum ForwardedEmailServiceType: Int, CaseIterable, Codable, Equatable, Menuable {
    // MARK: Cases

    /// Generate a forwarded email using addy.io.
    case addyIO = 0

    /// Generate a forwarded email using Firefox Relay.
    case firefoxRelay = 1

    /// Generate a forwarded email using SimpleLogin.
    case simpleLogin = 2

    /// Generate a forwarded email using DuckDuckGo.
    case duckDuckGo = 3

    /// Generate a forwarded email using Fastmail.
    case fastmail = 4

    /// Generate a forwarded email using ForwardEmail.
    case forwardEmail = 5

    // MARK: Static properties

    /// All of the cases to show in the menu.
    static let allCases: [Self] = [.addyIO, .duckDuckGo, .fastmail, .firefoxRelay, .forwardEmail, .simpleLogin]

    /// The default base URL for addy.io.
    static let defaultAddyIOBaseUrl = "https://app.addy.io"

    /// The default base URL for SimpleLogin.
    static let defaultSimpleLoginBaseUrl = "https://app.simplelogin.io"

    // MARK: Properties

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
        case .forwardEmail:
            return Localizations.forwardEmail
        case .simpleLogin:
            return Localizations.simpleLogin
        }
    }

    // MARK: Initialization

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(RawValue.self)
        // Handle unknown service types by defaulting to the first option (e.g. -1 for an unselected
        // service when migrating from the legacy app).
        self = Self(rawValue: rawValue) ?? .addyIO
    }
}
