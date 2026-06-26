import Foundation

/// The state for the manage passkeys screen.
///
struct ManagePasskeysState: Equatable {
    // MARK: Properties

    /// The list of passkeys registered via the Test Harness.
    var passkeys: [PasskeyEntry] = []

    /// The title of the screen.
    var title: String = Localizations.managePasskeys
}
