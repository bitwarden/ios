import Foundation

// MARK: - SetUpTwoFactorState

/// An object that defines the current state of a `SetUpTwoFactorView`.
///
struct SetUpTwoFactorState: Equatable, Sendable {
    /// The url to open in the device's web browser.
    var url: URL?
}
