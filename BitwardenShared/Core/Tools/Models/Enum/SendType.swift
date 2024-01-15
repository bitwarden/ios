// MARK: - SendType

/// An enum describing the type of data in a send.
///
enum SendType: Int, CaseIterable, Codable, Equatable, Menuable {
    /// The send contains text data.
    case text = 0

    /// The send contains an attached file.
    case file = 1

    // MARK: Type Properties

    static let allCases: [SendType] = [.file, .text]

    // MARK: Properties

    var localizedName: String {
        switch self {
        case .text: Localizations.text
        case .file: Localizations.file
        }
    }

    /// A flag indicating if this type requires a premium account to use.
    var requiresPremium: Bool {
        switch self {
        case .text: false
        case .file: true
        }
    }
}
