// MARK: - ViewItemAction

/// Actions that can be processed by a `ViewItemProcessor`.
enum ViewItemAction: Equatable {
    /// A card item action
    case cardItemAction(ViewCardItemAction)

    /// The check password button was pressed.
    case checkPasswordPressed

    /// A copy button was pressed for the given value.
    ///
    /// - Parameter value: The value to copy.
    case copyPressed(value: String)

    /// The visibility button was pressed for the specified custom field.
    case customFieldVisibilityPressed(CustomFieldState)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The edit button was pressed.
    case editPressed

    /// The more button was pressed.
    case morePressed(VaultItemManagementMenuAction)

    /// The password visibility button was pressed.
    case passwordVisibilityPressed

    /// A flag indicating if this action requires the user to reenter their master password to
    /// complete. This value works hand-in-hand with the `isMasterPasswordRequired` value in
    /// `ViewItemState`.
    var requiresMasterPasswordReprompt: Bool {
        switch self {
        case .cardItemAction,
             .copyPressed,
             .customFieldVisibilityPressed,
             .editPressed,
             .passwordVisibilityPressed:
            true
        case .checkPasswordPressed,
             .dismissPressed,
             .morePressed:
            false
        }
    }
}
