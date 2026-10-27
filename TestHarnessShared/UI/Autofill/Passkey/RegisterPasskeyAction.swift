// MARK: - RegisterPasskeyAction

/// Actions that can be processed by an `RegisterPasskeyProcessor`.
///
enum RegisterPasskeyAction: Equatable {
    /// The display name text field changed.
    case displayNameChanged(String)

    /// The relying party ID text field changed.
    case rpIdChanged(String)

    /// The username text field changed.
    case userNameChanged(String)
}
