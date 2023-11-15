/// The type of password to generate.
///
enum PasswordGeneratorType: String, CaseIterable, Codable, Equatable, Menuable {
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
