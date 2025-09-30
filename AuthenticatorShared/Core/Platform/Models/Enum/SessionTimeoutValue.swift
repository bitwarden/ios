import BitwardenKit
import BitwardenResources

// MARK: - SessionTimeoutValue

/// An enumeration of session timeout values to choose from.
/// BWA does not use the custom value.
///
extension SessionTimeoutValue: @retroactive CaseIterable, Menuable {
    /// All of the cases to show in the menu.
    public static let allCases: [Self] = [
        .immediately,
        .oneMinute,
        .fiveMinutes,
        .fifteenMinutes,
        .thirtyMinutes,
        .oneHour,
        .fourHours,
        .onAppRestart,
        .never,
    ]

    /// The localized string representation of a `SessionTimeoutValue`.
    var localizedName: String {
        switch self {
        case .immediately:
            Localizations.immediately
        case .oneMinute:
            Localizations.XMinutes(1)
        case .fiveMinutes:
            Localizations.XMinutes(5)
        case .fifteenMinutes:
            Localizations.XMinutes(15)
        case .thirtyMinutes:
            Localizations.XMinutes(30)
        case .oneHour:
            Localizations.XHours(1)
        case .fourHours:
            Localizations.XHours(4)
        case .onAppRestart:
            Localizations.onRestart
        case .never:
            Localizations.never
        case .custom:
            Localizations.custom
        }
    }
}
