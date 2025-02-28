// MARK: - ExportFileType

/// An enum describing the format of an export file.
/// This includes additional information necessary to perform the export
/// (such as password in the case of encrypted exports).
///
enum ExportFileType: Equatable {
    /// A `.csv` file type.
    case csv

    /// A `.json` file type.
    case json

    /// The file extension type to use.
    var fileExtension: String {
        switch self {
        case .csv:
            "csv"
        case .json:
            "json"
        }
    }
}
