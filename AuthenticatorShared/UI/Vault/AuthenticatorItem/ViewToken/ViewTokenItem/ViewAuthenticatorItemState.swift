import BitwardenSdk
import Foundation

// MARK: - ViewAuthenticatorItemState

/// The state for viewing/adding/editing a totp item
protocol ViewAuthenticatorItemState: Sendable {
    // MARK: Properties

    /// The TOTP key.
    var authenticatorKey: String? { get }

    /// The TOTP code model
    var totpCode: TOTPCodeModel? { get }
}
