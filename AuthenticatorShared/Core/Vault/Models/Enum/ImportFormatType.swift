// MARK: - ImportFormatType

/// An enum describing the format of the items item.
///
enum ImportFormatType: Menuable {
    /// A JSON exported from Bitwarden
    case bitwardenJson

    // MARK: Type Properties

    /// The ordered list of options to display in the menu.
    static let allCases: [ImportFormatType] = [.bitwardenJson]

    // MARK: Properties

    /// The name of the type to display in the dropdown menu.
    var localizedName: String {
        switch self {
        case .bitwardenJson:
            "Authenticator Export (JSON)"
        }
    }
}
