import SwiftUI

// MARK: - ManualEntryState

/// A sendable protocol to represent the state of manually entering an authenticator key.
///
protocol ManualEntryState: Sendable {
    /// The key for this item.
    var authenticatorKey: String { get set }

    /// The user's default save option (i.e. where to save the code).
    var defaultSaveOption: DefaultSaveOption { get set }

    /// Does the device support camera.
    var deviceSupportsCamera: Bool { get }

    /// A flag for indicating whether or not syncing with the password manager is active (i.e. the feature flag is on
    /// and the user has synced at least one account).
    var isPasswordManagerSyncActive: Bool { get set }

    /// The name for this item.
    var name: String { get set }
}

struct DefaultEntryState: ManualEntryState {
    var authenticatorKey: String = ""

    var defaultSaveOption: DefaultSaveOption = .none

    var deviceSupportsCamera: Bool

    var isPasswordManagerSyncActive = false

    var name: String = ""
}
