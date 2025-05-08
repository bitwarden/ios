// MARK: - ViewSendItemAction

/// Actions that can be processed by a `ViewSendItemProcessor`.
///
enum ViewSendItemAction: Equatable {
    /// The dismiss button was tapped.
    case dismiss

    /// The edit item button was tapped.
    case editItem
}
