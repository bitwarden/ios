import Foundation

/// The state for the use passkey test screen.
///
struct UsePasskeyState: Equatable {
    // MARK: Types

    /// The current status of a passkey assertion attempt.
    enum AssertionStatus: Equatable {
        /// Assertion failed with the associated error description.
        case failure(String)

        /// No assertion attempt has been made.
        case idle

        /// An assertion request is in progress.
        case inProgress

        /// The authenticator returned an assertion, but it did not verify against any stored
        /// credential, with the associated error description.
        case verificationFailure(String)

        /// Assertion completed successfully and was verified against the associated stored credential.
        case success(credential: StoredPasskeyCredential)
    }

    // MARK: Properties

    /// Whether the passkey error reference sheet is presented.
    var isHelpSheetPresented: Bool = false

    /// The relying party identifier (RP ID) for passkey assertion.
    var rpId: String = "bitwarden.pw"

    /// The current assertion status.
    var status: AssertionStatus = .idle

    /// The title of the screen.
    var title: String = Localizations.usePasskey
}
