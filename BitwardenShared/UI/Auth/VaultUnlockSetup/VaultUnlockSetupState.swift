// MARK: - VaultUnlockSetupState

/// An object that defines the current state of a `VaultUnlockSetupView`.
///
struct VaultUnlockSetupState: Equatable {
    // MARK: Types

    /// An enumeration of the vault unlock methods.
    ///
    enum UnlockMethod: Int, Equatable, Identifiable {
        /// Face ID is used to unlock the vault.
        case faceID

        /// The user's pin code is used to unlock the vault.
        case pin

        /// Touch ID is used to unlock the vault.
        case touchID

        /// The accessibility identifier for the UI toggle.
        var accessibilityIdentifier: String {
            switch self {
            case .faceID, .touchID:
                "UnlockWithBiometricsSwitch"
            case .pin:
                "UnlockWithPinSwitch"
            }
        }

        /// A key path for getting/setting whether the unlock method is turned on in the state.
        var keyPath: WritableKeyPath<VaultUnlockSetupState, Bool> {
            switch self {
            case .faceID, .touchID:
                \.isBiometricUnlockOn
            case .pin:
                \.isPinUnlockOn
            }
        }

        /// A unique identifier for the unlock method.
        var id: Int { rawValue }

        /// The localized title of the UI toggle.
        var title: String {
            switch self {
            case .faceID:
                Localizations.unlockWith(Localizations.faceID)
            case .pin:
                Localizations.unlockWithPIN
            case .touchID:
                Localizations.unlockWith(Localizations.touchID)
            }
        }
    }

    // MARK: Properties

    /// The biometric auth status for the user.
    var biometricsStatus: BiometricsUnlockStatus?

    /// Whether biometric unlock (Face ID / Touch ID) is turned on.
    var isBiometricUnlockOn = false

    /// Whether pin unlock is turned on.
    var isPinUnlockOn = false

    // MARK: Computed Properties

    /// Whether the continue button is enabled.
    var isContinueButtonEnabled: Bool {
        isBiometricUnlockOn || isPinUnlockOn
    }

    /// The available unlock methods to show in the UI.
    var unlockMethods: [UnlockMethod] {
        let biometricsMethod: UnlockMethod? = if case let .available(type, _, _) = biometricsStatus {
            switch type {
            case .faceID: .faceID
            case .touchID: .touchID
            }
        } else {
            nil
        }

        return [biometricsMethod, .pin].compactMap { $0 }
    }
}
