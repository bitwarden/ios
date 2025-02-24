import SwiftUI

extension View {
    /// Conditionally adds traits to a view
    ///
    /// - Parameters:
    ///     - condition: Should the traits be added?
    ///     - traits: The traits that could be added.
    ///
    /// - Returns: A view with or without traits added, conditionally.
    ///
    func accessibility(
        if condition: Bool = true,
        addTraits traits: AccessibilityTraits
    ) -> some View {
        accessibility(addTraits: condition ? traits : [])
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
    ) -> some View where S: StringProtocol {
        accessibilityAction(
            named: name, { Task { await asyncHandler() } }
        )
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
        _ handler: @escaping () -> Void
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
        _ asyncHandler: @escaping () async -> Void
    ) -> some View where S: StringProtocol {
        if condition {
            accessibilityAsyncAction(
                named: name
            ) {
                await asyncHandler()
            }
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
        onPressingChanged: ((Bool) -> Void)? = nil
    ) -> some View {
        if condition {
            onLongPressGesture(
                minimumDuration: minimumDuration,
                maximumDistance: maximumDistance,
                perform: action,
                onPressingChanged: onPressingChanged
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
        onPressingChanged: ((Bool) -> Void)? = nil
    ) -> some View {
        if condition {
            onLongPressGesture(
                minimumDuration: minimumDuration,
                maximumDistance: maximumDistance,
                perform: { Task { await asyncAction() } },
                onPressingChanged: onPressingChanged
            )
        } else {
            self
        }
    }

    /// Adds an async action to perform when this view recognizes a tap gesture.
    ///
    /// Use this method to perform the specified `action` when the user clicks
    /// or taps on the view or container `count` times.
    ///
    /// > Note: If you create a control that's functionally equivalent
    /// to a ``Button``, use ``ButtonStyle`` to create a customized button
    /// instead.
    ///
    /// In the example below, the color of the heart images changes to a random
    /// color from the `colors` array whenever the user clicks or taps on the
    /// view twice:
    ///
    ///     struct TapGestureExample: View {
    ///         let colors: [Color] = [.gray, .red, .orange, .yellow,
    ///                                .green, .blue, .purple, .pink]
    ///         @State private var fgColor: Color = .gray
    ///
    ///         var body: some View {
    ///             Image(systemName: "heart.fill")
    ///                 .resizable()
    ///                 .frame(width: 200, height: 200)
    ///                 .foregroundColor(fgColor)
    ///                 .onTapGesture(count: 2) {
    ///                     fgColor = colors.randomElement()!
    ///                 }
    ///         }
    ///     }
    ///
    /// ![A screenshot of a view of a heart.](SwiftUI-View-TapGesture.png)
    ///
    /// - Parameters:
    ///    - count: The number of taps or clicks required to trigger the action
    ///      closure provided in `action`. Defaults to `1`.
    ///    - asyncAction: The action to perform.
    public func onTapGesture(
        count: Int = 1,
        performAsync asyncAction: @escaping () async -> Void
    ) -> some View {
        onTapGesture(
            count: count,
            perform: {
                Task {
                    await asyncAction()
                }
            }
        )
    }
}
