import Foundation

/// Asynchronous effects that can be processed by an `EditAuthenticatorItemProcessor`
enum EditAuthenticatorItemEffect {
    /// The view appeared.
    case appeared

    /// The delete button was pressed.
    case deletePressed

    /// The save button was pressed.
    case savePressed
}
