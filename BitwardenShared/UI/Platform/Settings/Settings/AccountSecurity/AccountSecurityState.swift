import Foundation

// MARK: - UnlockMethod

/// The vault unlocking method.
///
public enum UnlockMethod {
    /// Unlocking with biometrics.
    case biometrics

    /// Unlocking with password.
    case password

    /// Unlocking with PIN.
    case pin
}

// MARK: - SessionTimeoutValue

/// An enumeration of session timeout values to choose from.
///
public enum SessionTimeoutValue: RawRepresentable, CaseIterable, Equatable, Menuable {
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

    /// A custom timeout value.
    case custom(Int)

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
        .custom(-100),
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
        case .custom:
            Localizations.custom
        }
    }

    public var rawValue: Int {
        switch self {
        case .immediately: 0
        case .oneMinute: 60
        case .fiveMinutes: 300
        case .fifteenMinutes: 900
        case .thirtyMinutes: 1800
        case .oneHour: 3600
        case .fourHours: 14400
        case .onAppRestart: -1
        case .never: -2
        case let .custom(customValue): customValue
        }
    }

    public init(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .immediately
        case 60:
            self = .oneMinute
        case 300:
            self = .fiveMinutes
        case 900:
            self = .fifteenMinutes
        case 1800:
            self = .thirtyMinutes
        case 3600:
            self = .oneHour
        case 14400:
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

// MARK: - SessionTimeoutAction

/// The action to perform on session timeout.
///
public enum SessionTimeoutAction: Int, CaseIterable, Codable, Equatable, Menuable {
    /// Lock the vault.
    case lock = 0

    /// Log the user out.
    case logout = 1

    /// All of the cases to show in the menu.
    public static let allCases: [SessionTimeoutAction] = [.lock, .logout]

    var localizedName: String {
        switch self {
        case .lock:
            Localizations.lock
        case .logout:
            Localizations.logOut
        }
    }
}

// MARK: - AccountSecurityState

/// An object that defines the current state of the `AccountSecurityView`.
///
struct AccountSecurityState: Equatable {
    /// The biometric auth status for the user.
    var biometricUnlockStatus: BiometricsUnlockStatus = .notAvailable

    /// The accessibility label used for the custom timeout value.
    var customTimeoutAccessibilityLabel: String {
        customTimeoutValue.timeInHoursMinutes(shouldSpellOut: true)
    }

    /// The custom session timeout value, initially set to 60 seconds.
    var customTimeoutValue: Int {
        guard case let .custom(customValue) = sessionTimeoutValue else {
            return 60
        }
        return customValue
    }

    /// The string representation of the custom session timeout value.
    var customTimeoutString: String {
        customTimeoutValue.timeInHoursMinutes()
    }

    /// The URL for account fingerprint phrase external link.
    var fingerprintPhraseUrl: URL?

    /// Whether the approve login requests toggle is on.
    var isApproveLoginRequestsToggleOn: Bool = false

    /// Whether or not the custom session timeout field is shown.
    var isShowingCustomTimeout: Bool {
        guard case .custom = sessionTimeoutValue else { return false }
        return true
    }

    /// Whether the unlock with pin code toggle is on.
    var isUnlockWithPINCodeOn: Bool = false

    /// The action taken when a session timeout occurs.
    var sessionTimeoutAction: SessionTimeoutAction = .lock

    /// The length of time before a session timeout occurs.
    var sessionTimeoutValue: SessionTimeoutValue = .immediately

    /// The URL for two step login external link.
    var twoStepLoginUrl: URL?
}
