import BitwardenResources

/// The value to use when generating a plus-addressed or catch-all email.
///
enum UsernameEmailType: Int, CaseIterable, Codable, Equatable, Menuable {
    /// Random values should be used to generate the email.
    case random = 0

    /// A website should be used to generate the email.
    case website = 1

    /// All of the cases to show in the menu.
    static let allCases: [Self] = [.random, .website]

    var localizedName: String {
        switch self {
        case .random:
            Localizations.random
        case .website:
            Localizations.website
        }
    }
}
