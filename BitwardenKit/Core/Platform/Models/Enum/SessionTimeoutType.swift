// MARK: - SessionTimeoutType

/// An enumeration of session timeout types to choose from.
///
public enum SessionTimeoutType: Codable, Equatable, Hashable, Sendable {
    /// Time out immediately.
    case immediately

    /// Time out on app restart.
    case onAppRestart

    /// Never time out the session.
    case never

    /// A custom timeout value.
    case custom

    // MARK: Properties

    /// The string representation of a session timeout type.
    public var rawValue: String {
        switch self {
        case .immediately:
            "immediately"
        case .onAppRestart:
            "onAppRestart"
        case .never:
            "never"
        case .custom:
            "custom"
        }
    }

    /// A safe string representation of the timeout type.
    public var timeoutType: String {
        switch self {
        case .immediately:
            "immediately"
        case .onAppRestart:
            "on app restart"
        case .never:
            "never"
        case .custom:
            "custom"
        }
    }

    // MARK: Initialization

    /// Initialize a `SessionTimeoutType` using a string of the  raw value.
    ///
    /// - Parameter rawValue: The string representation of the type raw value.
    ///
    public init(rawValue: String?) {
        switch rawValue {
        case "custom":
            self = .custom
        case "immediately":
            self = .immediately
        case "never":
            self = .never
        case "onAppRestart",
             "onSystemLock":
            self = .onAppRestart
        default:
            self = .custom
        }
    }

    /// Initialize a `SessionTimeoutType` using a SessionTimeoutValue that belongs to that type.
    ///
    /// - Parameter value: The SessionTimeoutValue that belongs to the type.
    ///
    public init(value: SessionTimeoutValue) {
        switch value {
        case .custom:
            self = .custom
        case .immediately:
            self = .immediately
        case .never:
            self = .never
        case .onAppRestart:
            self = .onAppRestart
        case .fifteenMinutes,
             .fiveMinutes,
             .fourHours,
             .oneHour,
             .oneMinute,
             .thirtyMinutes:
            self = .custom
        }
    }
}
