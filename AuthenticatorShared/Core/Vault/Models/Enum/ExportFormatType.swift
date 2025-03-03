// MARK: - ExportFormatType

/// An enum describing the format of the items export.
/// This is used in the UI to know if additional information (such as password)
/// needs to be acquired before doing the export.
///
enum ExportFormatType: Menuable {
    /// A CSV file.
    case csv

    /// A JSON file.
    case json

    // MARK: Type Properties

    /// The ordered list of options to display in the menu.
    static let allCases: [ExportFormatType] = [.json, .csv]

    // MARK: Properties

    /// The name of the type to display in the dropdown menu.
    var localizedName: String {
        switch self {
        case .csv:
            ".csv"
        case .json:
            ".json"
        }
    }
}
