import Combine
import Foundation
import UIKit

/// An observable responder to handle keyboard show/hide notifications.
final class KeyboardResponder: ObservableObject {
    // MARK: Properties

    /// Whether the keyboard is shown.
    @Published var isShown: Bool = false

    /// A publisher when the keyboard will hide.
    var keyboardWillHideNotification = NotificationCenter.default.publisher(
        for: UIResponder.keyboardWillHideNotification,
    )

    /// A publisher when the keyboard will show.
    var keyboardWillShowNotification = NotificationCenter.default.publisher(
        for: UIResponder.keyboardWillShowNotification,
    )

    // MARK: Initializer

    /// Initializes a `KeyboardResponder`.
    init() {
        keyboardWillHideNotification.map { _ in
            false
        }
        .assign(to: &$isShown)

        keyboardWillShowNotification.map { _ in
            true
        }
        .assign(to: &$isShown)
    }
}
