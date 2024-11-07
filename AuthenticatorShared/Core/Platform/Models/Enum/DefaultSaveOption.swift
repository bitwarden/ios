import Foundation

// MARK: - DefaultSaveOption

/// The default location for saving newly added keys via QR code scan and Manual entry.
///
enum DefaultSaveOption: String, Equatable, Menuable {
    /// Ask where to save a code each time a QR code is scanned.
    case none

    /// Save the code locally without showing any prompt.
    case saveLocally

    /// Take the user to the Bitwarden PM app to save the code without prompt.
    case saveToBitwarden

    /// All of the cases to show in the menu, in order.
    public static let allCases: [Self] = [
        .saveToBitwarden,
        .saveLocally,
        .none,
    ]

    /// The name of the value to display in the menu.
    var localizedName: String {
        switch self {
        case .none:
            Localizations.none
        case .saveLocally:
            Localizations.saveLocally
        case .saveToBitwarden:
            Localizations.saveToBitwarden
        }
    }
}
