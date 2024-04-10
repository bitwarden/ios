import BitwardenSdk

/// Synchronous actions that can be processed by an `EditItemProcessor`.
enum EditAuthenticatorItemAction: Equatable {
    /// The account field was changed.
    case accountChanged(String)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The key field was changed.
    case keyChanged(String)

    /// The item's name was changed
    case nameChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The toggle key visibility button was changed.
    case toggleKeyVisibilityChanged(Bool)
}
