import Foundation

/// Asynchronous effects that can be processed by an `EditTokenProcessor`
enum EditTokenEffect {
    /// The view appeared.
    case appeared

    /// The save button was pressed.
    case savePressed
}
