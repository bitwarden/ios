import Foundation

// MARK: - SessionTimeoutValue

/// The session timeout value.
///
public enum SessionTimeoutValue: CaseIterable, Equatable, Menuable {
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
    case custom

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
public enum SessionTimeoutAction: CaseIterable, Equatable, Menuable {
    /// Lock the vault.
    case lock

    /// Log the user out.
    case logout

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
        customSessionTimeoutValue.timeInHoursMinutes(shouldSpellOut: true)
    }

    /// The custom session timeout value, initially set to 1 minute.
    var customSessionTimeoutValue: TimeInterval = 60

    /// The string representation of the custom session timeout value.
    var customTimeoutString: String {
        customSessionTimeoutValue.timeInHoursMinutes()
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
}
