import BitwardenSdk

// MARK: - ViewTokenAction

/// Synchronous actions that can be processed by a `ViewTokenProcessor`.
enum ViewTokenAction: Equatable {
    /// A copy button was pressed for the given value.
    ///
    /// - Parameters:
    ///   - value: The value to copy.
    ///   - field: The field being copied.
    ///
    case copyPressed(value: String)

    /// The edit button was pressed.
    case editPressed

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
