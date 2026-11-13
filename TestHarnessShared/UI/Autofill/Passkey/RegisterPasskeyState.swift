import Foundation

// MARK: - RegisterPasskeyState

/// The state for the register passkey test screen.
///
struct RegisterPasskeyState: Equatable {
    // MARK: Types

    /// The current status of an passkey registration attempt.
    enum RegistrationStatus: Equatable {
        /// Registration failed with the associated error description.
        case failure(String)

        /// No registration attempt has been made.
        case idle

        /// A registration request is in progress.
        case inProgress

        /// Registration completed successfully, producing the credential ID below.
        case success(credentialId: String)
    }

    // MARK: Properties

    /// The display name for the passkey credential.
    var displayName: String = ""

    /// The relying party identifier (RP ID) for passkey registration.
    var rpId: String = "bitwarden.pw"

    /// The current registration status.
    var status: RegistrationStatus = .idle

    /// The title of the screen.
    var title: String = Localizations.registerPasskey

    /// The username for the passkey credential.
    var userName: String = ""
}
