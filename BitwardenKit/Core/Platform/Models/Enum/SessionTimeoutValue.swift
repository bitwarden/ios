// MARK: - SessionTimeoutValue

/// An enumeration of session timeout values to choose from.
///
/// Note: This is imported from the PM app, but the `custom` case has been removed.
///
public enum SessionTimeoutValue: RawRepresentable, Equatable, Hashable, Sendable {
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

    /// The session timeout value in seconds.
    public var seconds: Int {
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
