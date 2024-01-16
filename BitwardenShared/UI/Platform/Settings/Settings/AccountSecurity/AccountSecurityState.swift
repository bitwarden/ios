import Foundation

// MARK: - SessionTimeoutValue

/// An enumeration of session timeout values to choose from.
///
public enum SessionTimeoutValue: Int, CaseIterable, Equatable, Menuable {
    /// Timeout immediately.
    case immediately = 0

    /// Timeout after 1 minute.
    case oneMinute = 60

    /// Timeout after 5 minutes.
    case fiveMinutes = 300

    /// Timeout after 15 minutes.
    case fifteenMinutes = 900

    /// Timeout after 30 minutes.
    case thirtyMinutes = 1800

    /// Timeout after 1 hour.
    case oneHour = 3600

    /// Timeout after 4 hours.
    case fourHours = 14400

    /// Timeout on app restart.
    case onAppRestart = -1

    /// Never timeout the session.
    case never = -2

    /// A custom timeout value.
    case custom = -100

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
        .custom,
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
    /// The biometric authentication type for the user's device.
    var biometricAuthenticationType: BiometricAuthenticationType?

    /// The accessibility label used for the custom timeout value.
    var customTimeoutAccessibilityLabel: String {
        customTimeoutValue.timeInHoursMinutes(shouldSpellOut: true)
    }

    /// The custom session timeout value, initially set to 60 seconds.
    var customTimeoutValue: Int = 60

    /// The string representation of the custom session timeout value.
    var customTimeoutString: String {
        customTimeoutValue.timeInHoursMinutes()
    }

    /// Whether the approve login requests toggle is on.
    var isApproveLoginRequestsToggleOn: Bool = false

    /// Whether or not the custom session timeout field is shown.
    var isShowingCustomTimeout: Bool {
        sessionTimeoutValue == .custom
    }

    /// Whether the unlock with face ID toggle is on.
    var isUnlockWithFaceIDOn: Bool = false

    /// Whether the unlock with pin code toggle is on.
    var isUnlockWithPINCodeOn: Bool = false

    /// Whether the unlock with touch ID toggle is on.
    var isUnlockWithTouchIDToggleOn: Bool = false

    /// The action taken when a session timeout occurs.
    var sessionTimeoutAction: SessionTimeoutAction = .lock

    /// The length of time before a session timeout occurs.
    var sessionTimeoutValue: SessionTimeoutValue = .immediately

    /// The URL for two step login external link.
    var twoStepLoginUrl: URL?

    /// A dictionary mapping session timeout values and their numerical representations.
    /// e.g. `[0: .immediately]`
    var vaultTimeoutValues: [Int: SessionTimeoutValue] {
        var map: [Int: SessionTimeoutValue] = [:]
        for object in SessionTimeoutValue.allCases {
            map.updateValue(object, forKey: object.rawValue)
        }
        return map
    }
}
