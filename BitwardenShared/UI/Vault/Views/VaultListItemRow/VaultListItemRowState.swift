import Foundation

// MARK: - VaultListItemRowState

/// An object representing the visual state of a `VaultListItemRowView`.
struct VaultListItemRowState {
    // MARK: Properties

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// Whether we are in an extension context.
    var isFromExtension: Bool = false

    /// The item displayed in this row.
    var item: VaultListItem

    /// A flag indicating if this row should display a divider on the bottom edge.
    var hasDivider: Bool

    /// Whether the copy button for Totp rows is displayed.
    var showTotpCopyButton: Bool = true

    /// Whether to show the special web icons.
    var showWebIcons: Bool
}
