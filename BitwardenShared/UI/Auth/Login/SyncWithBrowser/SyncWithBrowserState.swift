import Foundation

// MARK: - SyncWithBrowserState

/// An object that defines the current state of a `SyncWithBrowserView`.
///
struct SyncWithBrowserState: Equatable, Sendable {
    // MARK: Properties

    /// The environment URL the user is trying to connect to.
    var environmentUrl: String = ""
}
