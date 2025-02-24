import Foundation

// MARK: - ItemListItemRowState

/// An object representing the visual state of an `ItemListItemRowView`.
struct ItemListItemRowState {
    // MARK: Properties

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// The item displayed in this row.
    var item: ItemListItem

    /// A flag indicating if this row should display a divider on the bottom edge.
    var hasDivider: Bool

    /// Whether to show the special web icons.
    var showWebIcons: Bool
}
