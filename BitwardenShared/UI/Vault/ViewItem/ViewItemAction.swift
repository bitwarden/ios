// MARK: - ViewItemAction

/// Actions that can be processed by a `ViewItemProcessor`.
enum ViewItemAction: Equatable {
    /// The check password button was pressed.
    case checkPasswordPressed

    /// A copy button was pressed for the given value.
    ///
    /// - Parameter value: The value to copy.
    case copyPressed(value: String)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The edit button was pressed.
    case editPressed

    /// The more button was pressed.
    case morePressed

    /// The password visibility button was pressed.
    case passwordVisibilityPressed
}
