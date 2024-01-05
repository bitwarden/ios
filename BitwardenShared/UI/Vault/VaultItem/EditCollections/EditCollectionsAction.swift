// MARK: - EditCollectionsAction

/// Actions that can be processed by a `EditCollectionsProcessor`.
///
enum EditCollectionsAction: Equatable {
    /// The toggle for including the item in a collection was changed.
    case collectionToggleChanged(Bool, collectionId: String)

    /// The dismiss button was pressed.
    case dismissPressed
}
