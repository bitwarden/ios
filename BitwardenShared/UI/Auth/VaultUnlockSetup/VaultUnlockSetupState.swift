import BitwardenResources

// MARK: - VaultUnlockSetupState

/// An object that defines the current state of a `VaultUnlockSetupView`.
///
struct VaultUnlockSetupState: Equatable {
    // MARK: Types

    /// An enumeration of the vault unlock methods.
    ///
    enum UnlockMethod: Equatable, Identifiable {
        /// Biometrics is used to unlock the vault.
        case biometrics(BiometricAuthenticationType)

        /// The user's pin code is used to unlock the vault.
        case pin

        /// The accessibility identifier for the UI toggle.
        var accessibilityIdentifier: String {
            switch self {
            case .biometrics:
                "UnlockWithBiometricsSwitch"
            case .pin:
                "UnlockWithPinSwitch"
            }
        }

        /// A key path for getting whether the unlock method is turned on in the state.
        var keyPath: KeyPath<VaultUnlockSetupState, Bool> {
            switch self {
            case .biometrics:
                \.isBiometricUnlockOn
            case .pin:
                \.isPinUnlockOn
            }
        }

        /// A unique identifier for the unlock method.
        var id: String {
            switch self {
            case let .biometrics(type):
                switch type {
                case .faceID:
                    "FaceID"
                case .touchID:
                    "TouchID"
                case .opticID:
                    "OpticID"
                case .unknown:
                    "biometrics"
                }
            case .pin:
                "PIN"
            }
        }

        /// The localized title of the UI toggle.
        var title: String {
            switch self {
            case let .biometrics(type):
                switch type {
                case .faceID:
                    Localizations.unlockWith(Localizations.faceID)
                case .opticID:
                    Localizations.unlockWith(Localizations.opticID)
                case .touchID:
                    Localizations.unlockWith(Localizations.touchID)
                case .unknown:
                    Localizations.unlockWithUnknownBiometrics
                }
            case .pin:
                Localizations.unlockWithPIN
            }
        }
    }

    // MARK: Properties

    /// The account setup flow that the user is in.
    var accountSetupFlow: AccountSetupFlow

    /// The biometric auth status for the user.
    var biometricsStatus: BiometricsUnlockStatus?

    /// Whether pin unlock is turned on.
    var isPinUnlockOn = false

    // MARK: Computed Properties

    /// Whether biometric unlock (Face ID / Touch ID) is turned on.
    var isBiometricUnlockOn: Bool {
        switch biometricsStatus {
        case let .available(_, enabled):
            return enabled
        case nil, .notAvailable:
            return false
        }
    }

    /// Whether the continue button is enabled.
    var isContinueButtonEnabled: Bool {
        isBiometricUnlockOn || isPinUnlockOn
    }

    /// The title to display in the navigation bar.
    var navigationBarTitle: String {
        switch accountSetupFlow {
        case .createAccount:
            Localizations.accountSetup
        case .settings:
            Localizations.setUpUnlock
        }
    }

    /// Whether the set up later button should be displayed.
    var shouldDisplaySetUpLaterButton: Bool {
        accountSetupFlow == .createAccount
    }

    /// The available unlock methods to show in the UI.
    var unlockMethods: [UnlockMethod] {
        guard case let .available(biometricsType, _) = biometricsStatus else {
            return [.pin]
        }
        return [.biometrics(biometricsType), .pin]
    }
}
