// MARK: - SDKUsePasskeyAction

/// Actions that can be processed by an `SDKUsePasskeyProcessor`.
///
enum SDKUsePasskeyAction: Equatable {
    /// The relying party ID text field changed.
    case rpIdChanged(String)
}
