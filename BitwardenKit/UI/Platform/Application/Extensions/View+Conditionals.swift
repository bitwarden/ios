import SwiftUI

// MARK: View+Conditionals

/// `View` modifiers that are applied conditionally.
///
public extension View {
    /// Conditionally adds accessibility traits to a view.
    ///
    /// - Parameters:
    ///     - condition: Should the traits be added?
    ///     - traits: The traits that could be added.
    ///
    /// - Returns: A view with or without traits added, conditionally.
    ///
    func accessibility(
        if condition: Bool = true,
        addTraits traits: AccessibilityTraits,
    ) -> some View {
        accessibility(addTraits: condition ? traits : [])
    }

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
    @ViewBuilder
    func conditionalAccessibilityAction<S>(
        if condition: Bool = true,
        named name: S,
        _ handler: @escaping () -> Void,
    ) -> some View where S: StringProtocol {
        if condition {
            accessibilityAction(named: name, handler)
        } else {
            self
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
    @ViewBuilder
    func conditionalAccessibilityAsyncAction<S>(
        if condition: Bool = true,
        named name: S,
        _ asyncHandler: @escaping () async -> Void,
    ) -> some View where S: StringProtocol {
        if condition {
            accessibilityAsyncAction(
                named: name,
            ) {
                await asyncHandler()
            }
        } else {
            self
        }
    }

    /// Conditionally hides a view based on the specified value.
    ///
    /// NOTE: This should only be used when the view needs to remain in the view hierarchy while hidden,
    /// which is often useful for sizing purposes (e.g. hide or swap a view without resizing the parent).
    /// Otherwise, `if condition { view }` is preferred.
    ///
    /// - Parameter hidden: `true` if the view should be hidden.
    /// - Returns The original view if `hidden` is false, or the view with the hidden modifier applied.
    ///
    @ViewBuilder
    func hidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }

    /// Conditionally applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder
    func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }

    /// Conditionally adds an action to perform when this view recognizes a long press
    /// gesture.
    ///
    /// - Parameters:
    ///     - condition: The condition that must be true for the long press to be relevant.
    ///     - minimumDuration: The minimum duration of the long press that must
    ///     elapse before the gesture succeeds.
    ///     - maximumDistance: The maximum distance that the fingers or cursor
    ///     performing the long press can move before the gesture fails.
    ///     - action: The action to perform when a long press is recognized.
    ///     - onPressingChanged:  A closure to run when the pressing state of the
    ///     gesture changes, passing the current state as a parameter.
    ///
    /// - Returns: The view with or without the long press gesture,
    ///    based on the supplied condition.
    ///
    @ViewBuilder
    func onLongPressGesture(
        if condition: Bool = true,
        minimumDuration: Double = 0.5,
        maximumDistance: CGFloat = 10,
        perform action: @escaping () -> Void,
        onPressingChanged: ((Bool) -> Void)? = nil,
    ) -> some View {
        if condition {
            onLongPressGesture(
                minimumDuration: minimumDuration,
                maximumDistance: maximumDistance,
                perform: action,
                onPressingChanged: onPressingChanged,
            )
        } else {
            self
        }
    }

    /// Conditionally adds an action to perform when this view recognizes a long press
    /// gesture.
    ///
    /// - Parameters:
    ///     - condition: The condition that must be true for the long press to be relevant.
    ///     - minimumDuration: The minimum duration of the long press that must
    ///     elapse before the gesture succeeds.
    ///     - maximumDistance: The maximum distance that the fingers or cursor
    ///     performing the long press can move before the gesture fails.
    ///     - asyncAction: The async action to perform when a long press is recognized.
    ///     - onPressingChanged:  A closure to run when the pressing state of the
    ///     gesture changes, passing the current state as a parameter.
    ///
    /// - Returns: The view with or without the long press gesture,
    ///    based on the supplied condition.
    ///
    @ViewBuilder
    func onLongPressGesture(
        if condition: Bool = true,
        minimumDuration: Double = 0.5,
        maximumDistance: CGFloat = 10,
        perform asyncAction: @escaping () async -> Void,
        onPressingChanged: ((Bool) -> Void)? = nil,
    ) -> some View {
        if condition {
            onLongPressGesture(
                minimumDuration: minimumDuration,
                maximumDistance: maximumDistance,
                perform: { Task { await asyncAction() } },
                onPressingChanged: onPressingChanged,
            )
        } else {
            self
        }
    }
}
