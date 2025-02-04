import SwiftUI

// MARK: - EmailAccessState

/// An object that defines the current state of a `EmailAccessView`.
///
struct EmailAccessState: Equatable, Sendable {
    // MARK: Properties

    /// Whether or not the user can delay setting up two-factor authentication.
    var allowDelay: Bool

    /// User-provided value for whether or not they can access their given email address.
    var canAccessEmail: Bool = false

    /// The user's email address.
    var emailAddress: String

    /// The url to open in the device's web browser.
    var url: URL?
}
