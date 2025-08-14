import BitwardenResources
import BitwardenSdk

// MARK: - SendType

/// An enum describing the type of data in a send.
///
public enum SendType: Int, CaseIterable, Codable, Equatable, Identifiable, Menuable, Sendable {
    /// The send contains text data.
    case text = 0

    /// The send contains an attached file.
    case file = 1

    // MARK: Type Properties

    public static let allCases: [SendType] = [.file, .text]

    // MARK: Properties

    var accessibilityId: String {
        switch self {
        case .text: "SendTextButton"
        case .file: "SendFileButton"
        }
    }

    public var id: Int {
        rawValue
    }

    public var localizedName: String {
        switch self {
        case .text: Localizations.text
        case .file: Localizations.file
        }
    }

    /// A flag indicating if this type requires a premium account to use.
    public var requiresPremium: Bool {
        switch self {
        case .text: false
        case .file: true
        }
    }
}
