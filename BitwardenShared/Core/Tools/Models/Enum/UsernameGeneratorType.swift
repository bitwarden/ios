import BitwardenResources

/// The type of username to generate.
///
enum UsernameGeneratorType: Int, CaseIterable, Codable, Equatable, Menuable {
    /// Generate a plus addressed email.
    case plusAddressedEmail = 0

    /// Generate a catch all email.
    case catchAllEmail = 1

    /// Generate a forwarded email.
    case forwardedEmail = 2

    /// Generate a random word.
    case randomWord = 3

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
