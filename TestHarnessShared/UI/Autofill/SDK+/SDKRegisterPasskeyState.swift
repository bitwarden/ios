import Foundation

// MARK: - SDKRegisterPasskeyState

/// The state for the SDK-backed register passkey test screen.
///
struct SDKRegisterPasskeyState: Equatable {
    // MARK: Types

    /// The current status of an SDK-backed passkey registration attempt.
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
    var title: String = Localizations.sdkRegisterPasskey

    /// The username for the passkey credential.
    var userName: String = ""
}
