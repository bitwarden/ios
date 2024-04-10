import Foundation

/// Asynchronous effects that can be processed by an `EditAuthenticatorItemProcessor`
enum EditAuthenticatorItemEffect {
    /// The view appeared.
    case appeared

    /// The save button was pressed.
    case savePressed
}
