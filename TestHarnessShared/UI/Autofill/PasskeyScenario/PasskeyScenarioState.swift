import Foundation

/// The state for the unified passkey scenario screen.
///
struct PasskeyScenarioState: Equatable {
    // MARK: Types

    /// The currently active tab.
    enum Mode: Int, CaseIterable, Equatable {
        /// The tab for asserting a passkey (sign-in).
        case authenticate

        /// The tab for registering a new passkey.
        case create

        /// The tab for managing registered passkeys.
        case manage

        var label: String {
            switch self {
            case .authenticate: Localizations.authenticate
            case .create: Localizations.create
            case .manage: Localizations.manage
            }
        }
    }

    /// The current status of a passkey assertion attempt.
    enum AssertionStatus: Equatable {
        /// Assertion failed with the associated error description.
        case failure(String)

        /// No assertion has been attempted.
        case idle

        /// An assertion request is in progress.
        case inProgress

        /// Assertion completed successfully.
        case success
    }

    /// The current status of a passkey registration attempt.
    enum RegistrationStatus: Equatable {
        /// Registration failed with the associated error description.
        case failure(String)

        /// No registration has been attempted.
        case idle

        /// A registration request is in progress.
        case inProgress

        /// Registration completed successfully.
        case success
    }

    // MARK: Properties

    /// The current assertion status.
    var assertionStatus: AssertionStatus = .idle

    /// The display name for the passkey credential.
    var displayName: String = ""

    /// The currently active tab.
    var mode: Mode = .create

    /// The list of passkeys registered via the Test Harness.
    var passkeys: [PasskeyEntry] = []

    /// The current registration status.
    var registrationStatus: RegistrationStatus = .idle

    /// The relying party identifier (RP ID).
    var rpId: String = "bitwarden.pw"

    /// The title of the screen.
    var title: String = Localizations.passkeys

    /// The username for the passkey credential.
    var userName: String = ""
}
