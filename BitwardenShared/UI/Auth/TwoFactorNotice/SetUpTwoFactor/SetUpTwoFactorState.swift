import Foundation

// MARK: - SetUpTwoFactorState

/// An object that defines the current state of a `SetUpTwoFactorView`.
///
struct SetUpTwoFactorState: Equatable, Sendable {
    /// Whether or not the user can delay setting up two-factor authentication.
    var allowDelay: Bool

    /// The user's email address.
    var emailAddress: String

    /// The url to open in the device's web browser.
    var url: URL?
}
