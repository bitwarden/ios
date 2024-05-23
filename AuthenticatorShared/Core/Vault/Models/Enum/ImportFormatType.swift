// MARK: - ImportFormatType

/// An enum describing the format of the imported items file by provider.
/// This is used in the UI to know if additional information (such as password)
/// needs to be acquired before doing the import.
///
enum ImportFormatType: Menuable {
    /// A JSON exported from Bitwarden
    case bitwardenJson

    /// A JSON exported from Lastpass
    case lastpassJson

    /// A JSON exported from Raivo
    case raivoJson

    /// A JSON exported from 2FAS
    case twoFasJason

    // MARK: Type Properties

    /// The ordered list of options to display in the menu.
    static let allCases: [ImportFormatType] = [
        .bitwardenJson,
        .lastpassJson,
        .raivoJson,
        .twoFasJason,
    ]

    // MARK: Properties

    /// The file selection route to use for finding files of this type.
    var fileSelectionRoute: FileSelectionRoute {
        switch self {
        case .bitwardenJson,
             .lastpassJson,
             .raivoJson:
            return .jsonFile
        case .twoFasJason:
            return .file
        }
    }

    /// The name of the type to display in the dropdown menu.
    var localizedName: String {
        switch self {
        case .bitwardenJson:
            "Authenticator Export (JSON)"
        case .lastpassJson:
            "LastPass (JSON)"
        case .raivoJson:
            "Raivo (JSON)"
        case .twoFasJason:
            "2FAS (.2fas)"
        }
    }
}
