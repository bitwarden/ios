import Foundation

// MARK: - SsoSyncErrorState

/// An object that defines the current state of a `SsoSyncErrorView`.
///
struct SsoSyncErrorState: Equatable, Sendable {
    // MARK: Properties

    /// The environment URL the user is trying to connect to.
    var environmentUrl: String = ""

    /// The url to open in the device's web browser.
    var url: URL?
}
