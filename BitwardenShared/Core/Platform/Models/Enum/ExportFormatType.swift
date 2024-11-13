// MARK: - ExportFormatType

/// An enum describing the format of the vault export.
///
enum ExportFormatType: Menuable {
    /// A CSV file.
    case csv
    
    /// Using Credential Exchange Protocol.
    case cxp

    /// A JSON file.
    case json

    /// An encrypted JSON file.
    case jsonEncrypted

    // MARK: Type Properties

    /// The ordered list of options to display in the menu.
    static let allCases: [ExportFormatType] = [.json, .csv, .jsonEncrypted, .cxp]

    // MARK: Properties

    /// The name of the type to display in the dropdown menu.
    var localizedName: String {
        switch self {
        case .csv:
            ".csv"
        case .cxp:
            "Credential Exchange"
        case .json:
            ".json"
        case .jsonEncrypted:
            ".json (Password protected)"
        }
    }
}
