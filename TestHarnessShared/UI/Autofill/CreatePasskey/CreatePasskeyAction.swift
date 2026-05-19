import Foundation

/// Actions that can be processed by a `CreatePasskeyProcessor`.
///
enum CreatePasskeyAction: Equatable {
    /// The display name field was updated.
    case displayNameChanged(String)

    /// The relying party ID field was updated.
    case rpIdChanged(String)

    /// The username field was updated.
    case userNameChanged(String)
}
