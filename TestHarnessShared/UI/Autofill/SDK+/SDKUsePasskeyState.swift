import Foundation

// MARK: - SDKUsePasskeyState

/// The state for the SDK-backed use passkey test screen.
///
struct SDKUsePasskeyState: Equatable {
    // MARK: Types

    /// The current status of an SDK-backed passkey assertion attempt.
    enum AssertionStatus: Equatable {
        /// Assertion failed with the associated error description.
        case failure(String)

        /// No assertion attempt has been made.
        case idle

        /// An assertion request is in progress.
        case inProgress

        /// Assertion completed successfully for the associated credential.
        case success(credentialId: String, userName: String?)
    }

    // MARK: Properties

    /// The relying party identifier (RP ID) for passkey assertion.
    var rpId: String = "bitwarden.pw"

    /// The current assertion status.
    var status: AssertionStatus = .idle

    /// The title of the screen.
    var title: String = Localizations.sdkUsePasskey
}
