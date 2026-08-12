import BitwardenSdk
import Foundation

// MARK: - UsePasskeyState

/// The state for the SDK-backed use passkey test screen.
///
struct UsePasskeyState: Equatable {
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
        case success(credentialId: String, rpId: String, userName: String?)
    }

    // MARK: Properties

    /// Whether the registered credentials are still being loaded.
    var isLoadingCredentials = true

    /// The credentials registered so far, across app launches.
    var registeredCredentials: [Fido2CredentialAutofillView] = []

    /// The current assertion status.
    var status: AssertionStatus = .idle

    /// The title of the screen.
    var title: String = Localizations.usePasskey
}
