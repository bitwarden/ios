import BitwardenKit
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

    /// An unknown or unimplemented send type.
    case unknown = -1

    // MARK: Type Properties

    public static let allCases: [SendType] = [.file, .text]

    // MARK: Properties

    public var accessibilityId: String {
        switch self {
        case .text: "SendTextButton"
        case .file: "SendFileButton"
        case .unknown: ""
        }
    }

    public var id: Int {
        rawValue
    }

    public var localizedName: String {
        switch self {
        case .text: Localizations.text
        case .file: Localizations.file
        case .unknown: ""
        }
    }

    /// A flag indicating if this type requires a Premium account to use.
    public var requiresPremium: Bool {
        switch self {
        case .text: false
        case .file: true
        case .unknown: false
        }
    }
}

// MARK: - DefaultValueProvider

extension SendType: DefaultValueProvider {
    public static var defaultValue: SendType { .unknown }
}
