// MARK: ViewSSHKeyItemAction

/// An enum of actions for an SSH key Item in its view state.
///
enum ViewSSHKeyItemAction: Equatable {
    /// A copy button was pressed for the given value.
    ///
    /// - Parameters:
    ///   - value: The value to copy.
    ///   - field: The field being copied.
    ///
    case copyPressed(value: String, field: CopyableField)

    /// The private key visibility button was pressed.
    case privateKeyVisibilityPressed
}
