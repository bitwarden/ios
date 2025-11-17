import BitwardenKit
import BitwardenResources
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
extension SessionTimeoutValue: @retroactive CaseIterable {
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
}

extension SessionTimeoutValue {
    var minutesValue: Int? {
        switch self {
        case .immediately: 0
        case .oneMinute: 1
        case .fiveMinutes: 5
        case .fifteenMinutes: 15
        case .thirtyMinutes: 30
        case .oneHour: 60
        case .fourHours: 240
        case let .custom(minutes) where minutes >= 0: minutes
        case .custom, .never, .onAppRestart: nil
        }
    }

    var isCustomPlaceholder: Bool {
        if case let .custom(minutes) = self {
            minutes < 0
        } else {
            false
        }
    }
}

// MARK: - AccountSecurityState

/// An object that defines the current state of the `AccountSecurityView`.
///
struct AccountSecurityState: Equatable {
    // MARK: Properties

    /// The timeout actions to show when the policy for maximum timeout value is in effect.
    var availableTimeoutActions: [SessionTimeoutAction] = SessionTimeoutAction.allCases

    /// The timeout options to show when the policy for maximum timeout value is in effect.
    var availableTimeoutOptions: [SessionTimeoutValue] {
        availableTimeoutOptions(
            type: policyTimeoutType,
            value: policyTimeoutValue,
        )
    }

    /// The state of the badges in the settings tab.
    var badgeState: SettingsBadgeState?

    /// The biometric auth status for the user.
    var biometricUnlockStatus: BiometricsUnlockStatus = .notAvailable

    /// The URL for account fingerprint phrase external link.
    var fingerprintPhraseUrl: URL?

    /// Whether the user has a master password.
    var hasMasterPassword = true

    /// Whether the user has enabled the sync with the authenticator app..
    var isAuthenticatorSyncEnabled = false

    /// Whether the timeout action policy is in effect.
    var isPolicyTimeoutActionEnabled = false

    /// Whether the timeout policy is in effect.
    var isPolicyTimeoutEnabled = false

    /// Whether the unlock with pin code toggle is on.
    var isUnlockWithPINCodeOn: Bool = false

    /// The policy's maximum vault timeout value.
    var policyTimeoutValue: Int = 0

    /// The policy's timeout action, if set.
    var policyTimeoutAction: SessionTimeoutAction?

    /// The policy's timeout type, if set.
    var policyTimeoutType: SessionTimeoutType?

    /// Whether the policy to remove Unlock with pin feature is enabled.
    var removeUnlockWithPinPolicyEnabled: Bool = false

    /// The action taken when a session timeout occurs.
    var sessionTimeoutAction: SessionTimeoutAction = .lock

    /// The length of time before a session timeout occurs.
    var sessionTimeoutType: SessionTimeoutType = .immediately

    /// The length of time before a session timeout occurs.
    var sessionTimeoutValue: SessionTimeoutValue = .immediately

    /// The URL for two step login external link.
    var twoStepLoginUrl: URL?

    // MARK: Computed Properties

    /// The accessibility label used for the custom timeout value.
    var customTimeoutAccessibilityLabel: String {
        customTimeoutValueSeconds.timeInHoursMinutes(shouldSpellOut: true)
    }

    /// The custom session timeout value, in seconds, initially set to 60 seconds.
    var customTimeoutValueSeconds: Int {
        guard case let .custom(customValueInMinutes) = sessionTimeoutValue, customValueInMinutes > 0 else {
            return 60
        }
        return customValueInMinutes * 60
    }

    /// The string representation of the custom session timeout value.
    var customTimeoutString: String {
        customTimeoutValueSeconds.timeInHoursMinutes()
    }

    /// Whether the user has a method to unlock the vault (master password, pin set, or biometrics
    /// enabled).
    var hasUnlockMethod: Bool {
        hasMasterPassword || isUnlockWithPINCodeOn || biometricUnlockStatus.isEnabled
    }

    /// Whether the lock now button should be visible.
    var isLockNowVisible: Bool {
        hasUnlockMethod
    }

    /// Whether the session timeout action row/picker should be disabled.
    var isSessionTimeoutActionDisabled: Bool {
        !hasUnlockMethod || isTimeoutActionPolicyEnabled
    }

    var isSessionTimeoutPickerDisabled: Bool {
        guard case .immediately = policyTimeoutType else { return false }
        return true
    }

    /// Whether the timeout policy specifies a timeout action.
    var isTimeoutActionPolicyEnabled: Bool {
        policyTimeoutAction != nil
    }

    /// Whether or not the custom session timeout field is shown.
    var isShowingCustomTimeout: Bool {
        guard case .custom = sessionTimeoutValue else { return false }
        return true
    }

    /// The message to display if a timeout action is in effect for the user.
    var policyTimeoutActionMessage: String? {
        guard isTimeoutActionPolicyEnabled else { return nil }
        return Localizations.thisSettingIsManagedByYourOrganization
    }

    /// The policy's timeout value in hours.
    var policyTimeoutHours: Int {
        policyTimeoutValue / 60
    }

    /// The message to display if a timeout policy is in effect for the user.
    var policyTimeoutMessage: String? {
        guard !isShowingCustomTimeout else { return nil }
        return policyTimeoutCustomMessage
    }

    /// The message to display if a timeout policy is in effect for the user.
    var policyTimeoutCustomMessage: String? {
        guard isPolicyTimeoutEnabled, let policy = policyTimeoutType else { return nil }
        switch policyTimeoutType {
        case .custom:
            return customTimeoutMessage
        case .immediately:
            return Localizations.thisSettingIsManagedByYourOrganization
        case .never:
            return Localizations.yourOrganizationHasSetTheDefaultSessionTimeoutToX(policy.timeoutType)
        case .onAppRestart:
            return Localizations.yourOrganizationHasSetTheDefaultSessionTimeoutToX(policy.timeoutType)
        default:
            return customTimeoutMessage
        }
    }

    /// The policy's timeout value in minutes.
    var policyTimeoutMinutes: Int {
        policyTimeoutValue % 60
    }

    /// Whether to show/hide unlock options.
    var showUnlockOptions: Bool {
        guard case .available = biometricUnlockStatus else {
            return unlockWithPinFeatureAvailable
        }
        return true
    }

    /// Whether the unlock with Pin feature is available.
    var unlockWithPinFeatureAvailable: Bool {
        !removeUnlockWithPinPolicyEnabled || isUnlockWithPINCodeOn
    }

    var customTimeoutMessage: String {
        switch (policyTimeoutHours, policyTimeoutMinutes) {
        case let (hours, minutes) where hours > 0 && minutes > 0:
            Localizations.yourOrganizationHasSetTheDefaultSessionTimeoutToXAndY(
                Localizations.xHours(
                    policyTimeoutHours,
                ),
                Localizations.xMinutes(
                    policyTimeoutMinutes,
                ),
            )
        case let (hours, _) where hours > 0:
            Localizations.yourOrganizationHasSetTheDefaultSessionTimeoutToX(
                Localizations.xHours(
                    policyTimeoutHours,
                ),
            )
        default:
            Localizations.yourOrganizationHasSetTheDefaultSessionTimeoutToX(
                Localizations.xMinutes(
                    policyTimeoutMinutes,
                ),
            )
        }
    }

    /// Returns the available timeout options based on policy type and value.
    ///
    /// - Parameters:
    ///   - type: The policy's timeout type, if set.
    ///   - value: The policy's maximum vault timeout value.
    /// - Returns: Filtered array of available session timeout values.
    private func availableTimeoutOptions(
        type: SessionTimeoutType?,
        value: Int,
    ) -> [SessionTimeoutValue] {
        SessionTimeoutValue.allCases.filter { option in
            switch type {
            case .never:
                return true
            case .onAppRestart:
                return option != .never
            case .immediately:
                return option == .immediately
            case .custom:
                if option.isCustomPlaceholder { return true }
                guard let time = option.minutesValue else { return false }
                return time <= value
            case nil:
                if value > 0 {
                    if option.isCustomPlaceholder { return true }
                    guard let time = option.minutesValue else { return false }
                    return time <= value
                } else {
                    return true
                }
            }
        }
    }
}
