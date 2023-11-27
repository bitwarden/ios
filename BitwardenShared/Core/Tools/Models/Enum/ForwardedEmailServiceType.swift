/// The service used to generate a forwarded email alias.
///
enum ForwardedEmailServiceType: Int, CaseIterable, Codable, Equatable, Menuable {
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

    /// All of the cases to show in the menu.
    static let allCases: [Self] = [.addyIO, .duckDuckGo, .fastmail, .firefoxRelay, .simpleLogin]

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
