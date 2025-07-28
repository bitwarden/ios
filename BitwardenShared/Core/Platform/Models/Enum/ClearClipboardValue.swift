import BitwardenResources
import Foundation

// MARK: - ClearClipboardValue

/// The time after which the clipboard should be cleared.
///
enum ClearClipboardValue: Int, Menuable {
    /// Do not clear the clipboard.
    case never = -1

    /// Clear the clipboard after ten seconds.
    case tenSeconds = 10

    /// Clear the clipboard after twenty seconds.
    case twentySeconds = 20

    /// Clear the clipboard after thirty seconds.
    case thirtySeconds = 30

    /// Clear the clipboard after one minute.
    case oneMinute = 60

    /// Clear the clipboard after two minutes.
    case twoMinutes = 120

    /// Clear the clipboard after five minutes.
    case fiveMinutes = 300

    /// All of the cases to show in the menu, in order.
    public static let allCases: [Self] = [
        .never,
        .tenSeconds,
        .twentySeconds,
        .thirtySeconds,
        .oneMinute,
        .twoMinutes,
        .fiveMinutes,
    ]

    /// The name of the value to display in the menu.
    var localizedName: String {
        switch self {
        case .never:
            Localizations.never
        case .tenSeconds:
            Localizations.tenSeconds
        case .twentySeconds:
            Localizations.twentySeconds
        case .thirtySeconds:
            Localizations.thirtySeconds
        case .oneMinute:
            Localizations.oneMinute
        case .twoMinutes:
            Localizations.twoMinutes
        case .fiveMinutes:
            Localizations.fiveMinutes
        }
    }
}
