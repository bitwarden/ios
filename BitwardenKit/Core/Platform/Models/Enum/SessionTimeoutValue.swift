import BitwardenResources

// MARK: - SessionTimeoutValue

/// An enumeration of session timeout values to choose from.
///
public enum SessionTimeoutValue: Codable, RawRepresentable, Equatable, Hashable, Menuable, Sendable {
    /// Time out immediately.
    case immediately

    /// Time out after 1 minute.
    case oneMinute

    /// Time out after 5 minutes.
    case fiveMinutes

    /// Time out after 15 minutes.
    case fifteenMinutes

    /// Time out after 30 minutes.
    case thirtyMinutes

    /// Time out after 1 hour.
    case oneHour

    /// Time out after 4 hours.
    case fourHours

    /// Time out on app restart.
    case onAppRestart

    /// Never time out the session.
    case never

    /// A custom timeout value.
    case custom(Int)

    /// The session timeout value in seconds.
    public var seconds: Int {
        rawValue * 60
    }

    /// The localized string representation of a `SessionTimeoutValue`.
    public var localizedName: String {
        switch self {
        case .immediately:
            Localizations.immediately
        case .oneMinute:
            Localizations.xMinutes(1)
        case .fiveMinutes:
            Localizations.xMinutes(5)
        case .fifteenMinutes:
            Localizations.xMinutes(15)
        case .thirtyMinutes:
            Localizations.xMinutes(30)
        case .oneHour:
            Localizations.xHours(1)
        case .fourHours:
            Localizations.xHours(4)
        case .onAppRestart:
            Localizations.onRestart
        case .never:
            Localizations.never
        case .custom:
            Localizations.custom
        }
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
        case let .custom(customValue): customValue
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
            self = .custom(rawValue)
        }
    }
}
