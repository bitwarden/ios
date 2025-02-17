// MARK: - SessionTimeoutValue

/// An enumeration of session timeout values to choose from.
///
/// Note: This is imported from the PM app, but the `custom` case has been removed.
///
public enum SessionTimeoutValue: RawRepresentable, CaseIterable, Equatable, Menuable, Sendable {
    /// Timeout immediately.
    case immediately

    /// Timeout after 1 minute.
    case oneMinute

    /// Timeout after 5 minutes.
    case fiveMinutes

    /// Timeout after 15 minutes.
    case fifteenMinutes

    /// Timeout after 30 minutes.
    case thirtyMinutes

    /// Timeout after 1 hour.
    case oneHour

    /// Timeout after 4 hours.
    case fourHours

    /// Timeout on app restart.
    case onAppRestart

    /// Never timeout the session.
    case never

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
            Localizations.oneMinute
        case .fiveMinutes:
            Localizations.fiveMinutes
        case .fifteenMinutes:
            Localizations.fifteenMinutes
        case .thirtyMinutes:
            Localizations.thirtyMinutes
        case .oneHour:
            Localizations.oneHour
        case .fourHours:
            Localizations.fourHours
        case .onAppRestart:
            Localizations.onRestart
        case .never:
            Localizations.never
        }
    }

    /// The session timeout value in seconds.
    var seconds: Int {
        rawValue * 60
    }

    /// The session timeout value in minutes.
    public var rawValue: Int {
        switch self {
        case .immediately: 0
        case .oneMinute: 1
        case .fiveMinutes: 5
        case .fifteenMinutes: 15
        case .thirtyMinutes: 30
        case .oneHour: 60
        case .fourHours: 240
        case .onAppRestart: -1
        case .never: -2
        }
    }

    public init(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .immediately
        case 1:
            self = .oneMinute
        case 5:
            self = .fiveMinutes
        case 15:
            self = .fifteenMinutes
        case 30:
            self = .thirtyMinutes
        case 60:
            self = .oneHour
        case 240:
            self = .fourHours
        case -1:
            self = .onAppRestart
        case -2:
            self = .never
        default:
            self = .never
        }
    }
}
