// MARK: - ImportFileType

/// An enum describing the format of an import file.
///
public enum ImportFileType: Equatable {
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
