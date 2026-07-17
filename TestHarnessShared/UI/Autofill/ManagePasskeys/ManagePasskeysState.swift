import Foundation

/// The state for the manage passkeys test screen.
///
struct ManagePasskeysState: Equatable {
    // MARK: Properties

    /// The stored passkey credentials, sorted by creation date, most recent first.
    var credentials: [StoredPasskeyCredential] = []

    /// The title of the screen.
    var title: String = Localizations.managePasskeys
}
