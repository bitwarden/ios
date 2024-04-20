// MARK: - ExportFileType

/// An enum describing the format of an export file.
///
enum ExportFileType: Equatable {
    /// A `.json` file type.
    case json

    /// The file extension type to use.
    var fileExtension: String {
        switch self {
        case .json:
            "json"
        }
    }
}
