import Foundation

// MARK: - VaultListItemRowState

/// An object representing the visual state of a `VaultListItemRowView`.
struct VaultListItemRowState {
    // MARK: Properties

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// The item displayed in this row.
    var item: VaultListItem

    /// A flag indicating if this row should display a divider on the bottom edge.
    var hasDivider: Bool

    /// Whether to show the special web icons.
    var showWebIcons: Bool
}
