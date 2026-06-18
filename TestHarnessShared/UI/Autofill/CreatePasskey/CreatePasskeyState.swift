import Foundation

/// The state for the create passkey test screen.
///
struct CreatePasskeyState: Equatable {
    // MARK: Types

    /// The current status of a passkey registration attempt.
    enum RegistrationStatus: Equatable {
        /// No registration attempt has been made.
        case idle

        /// A registration request is in progress.
        case inProgress

        /// Registration completed successfully.
        case success

        /// Registration failed with the associated error description.
        case failure(String)
    }

    // MARK: Properties

    /// The display name for the passkey credential.
    var displayName: String = ""

    /// The relying party identifier (RP ID) for passkey registration.
    var rpId: String = "bitwarden.pw"

    /// The current registration status.
    var status: RegistrationStatus = .idle

    /// The title of the screen.
    var title: String = "Create Passkey"

    /// The username for the passkey credential.
    var userName: String = ""
}
