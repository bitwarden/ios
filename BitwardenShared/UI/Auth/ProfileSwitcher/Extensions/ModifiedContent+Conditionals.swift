import SwiftUI

extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {
    /// Conditionally adds an accessibility action to the view.
    ///
    /// - Parameters:
    ///   - condition: The condition that must be true in order for the action to be applied.
    ///   - name: The name of the action.
    ///   - handler: The action.
    ///
    /// - Returns: A modifeid version of the content, with or without the accessibility action,
    ///    based on the supplied condition.
    ///
    func conditionalAccessibilityAction<S>(
        if condition: Bool = true,
        named name: S,
        _ handler: @escaping () -> Void
    ) -> ModifiedContent<Content, Modifier> where S: StringProtocol {
        if condition {
            return accessibilityAction(named: name, handler)
        } else {
            return self
        }
    }

    /// Conditionally adds an accessibility action to the view.
    ///
    /// - Parameters:
    ///   - condition: The condition that must be true in order for the action to be applied.
    ///   - name: The name of the action.
    ///   - asyncHandler: The async action.
    ///
    /// - Returns: A modifeid version of the content, with or without the accessibility action,
    ///    based on the supplied condition.
    ///
    func conditionalAccessibilityAsyncAction<S>(
        if condition: Bool = true,
        named name: S,
        _ asyncHandler: @escaping () async -> Void
    ) -> ModifiedContent<Content, Modifier> where S: StringProtocol {
        if condition {
            return accessibilityAsyncAction(
                named: name
            ) {
                await asyncHandler()
            }
        } else {
            return self
        }
    }

    /// Adds an async accessibility action to the view.
    ///
    /// - Parameters:
    ///   - name: The name of the action.
    ///   - asyncHandler: The async action.
    ///
    /// - Returns: A modifeid version of the content, with or without the accessibility action,
    ///    based on the supplied condition.
    ///
    func accessibilityAsyncAction<S>(
        named name: S,
        _ asyncHandler: @escaping () async -> Void
    ) -> ModifiedContent<Content, Modifier> where S: StringProtocol {
        accessibilityAction(
            named: name, { Task { await asyncHandler() } }
        )
    }
}
